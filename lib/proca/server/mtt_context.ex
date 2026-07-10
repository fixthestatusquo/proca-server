defmodule Proca.Server.MTTContext do
  @moduledoc """
  The MTT context.
  """

  import Ecto.Query
  alias Proca.Repo

  alias Swoosh.Email
  alias Proca.Action.Message
  alias Proca.{Campaign, ActionPage, TargetEmail}
  alias Proca.Service.{EmailTemplate, EmailMerge, EmailBackend, EmailTemplateDirectory}
  import Proca.Stage.Support, only: [camel_case_keys: 1]

  require Logger

  @default_locale "en"
  # 1 day ago
  @recent_test_messages -1 * 60 * 60 * 24

  def emit_delivery(result, metadata \\ %{}) do
    metadata =
      Map.merge(
        %{
          kind: :live,
          result: result,
          reason: :none,
          org_id: nil,
          campaign_id: nil,
          drip_delivery: nil
        },
        Map.new(metadata)
      )

    :telemetry.execute([:proca, :mtt, :delivery], %{count: 1}, metadata)
  end

  def get_active_targets do
    today = Date.utc_today()

    from(
      target in Proca.Target,
      join: campaign in assoc(target, :campaign),
      join: mtt in assoc(campaign, :mtt),
      join: org in assoc(campaign, :org),
      join: email_backend in assoc(org, :email_backend),
      join: te in assoc(target, :emails),
      where:
        mtt.drip_delivery == false and
          not is_nil(email_backend) and
          te.email_status in [:active, :none] and
          fragment("?::date", mtt.start_at) <= ^today and
          fragment("?::date", mtt.end_at) >= ^today,
      order_by: fragment("RANDOM()"),
      distinct: target.id,
      select: %{
        target
        | campaign: %{campaign | mtt: mtt, org: %{org | email_backend: email_backend}}
      }
    )
    |> Repo.all()
  end

  @doc """
  Fetch a single target with the associations `deliver_message/2` needs.
  Returns nil if the target is gone or its org has no email backend.
  """
  def get_target(target_id) do
    from(
      target in Proca.Target,
      join: campaign in assoc(target, :campaign),
      join: mtt in assoc(campaign, :mtt),
      join: org in assoc(campaign, :org),
      join: email_backend in assoc(org, :email_backend),
      where: target.id == ^target_id,
      select: %{
        target
        | campaign: %{campaign | mtt: mtt, org: %{org | email_backend: email_backend}}
      }
    )
    |> Repo.one()
  end

  @doc """
  Fetch a message by id, only if still unsent. Used by `Proca.Stage.MTT` to
  re-check the sent flag at consume time (idempotent on queue re-delivery).
  """
  def get_unsent_message(message_id) do
    from(m in Message,
      join: a in assoc(m, :action),
      where: m.id == ^message_id and m.sent == false and a.processing_status == :delivered,
      preload: [
        target: :emails,
        message_content: [],
        action: [:supporter, action_page: :org]
      ]
    )
    |> Repo.one()
  end

  @doc """
  Route a message for delivery through the org's `wrk.N.mtt` RabbitMQ queue.

  Fails closed when the org topology or RabbitMQ publishing is unavailable.
  The database message remains unsent so a later scheduler run can retry it.
  """
  def dispatch_message(target, msg) do
    org = target.campaign.org
    queue = Proca.Pipes.Topology.mtt_queue(org)
    payload = %{messageId: msg.id, targetId: target.id}

    metadata = [
      org_id: org.id,
      campaign_id: target.campaign.id,
      drip_delivery: target.campaign.mtt.drip_delivery
    ]

    result =
      cond do
        Proca.Server.MTT.dry_run?() ->
          :dry_run

        Proca.Server.MTT.mode() != :enabled ->
          {:error, :mtt_disabled}

        not is_pid(Proca.Pipes.Topology.whereis(org)) ->
          {:error, :mtt_queue_unavailable}

        true ->
          Proca.Pipes.Connection.publish(payload, "", queue)
      end

    case result do
      :ok -> emit_delivery(:published, metadata)
      :dry_run -> emit_delivery(:dry_run, metadata)
      {:error, reason} -> emit_delivery(:publish_failed, Keyword.put(metadata, :reason, reason))
    end

    result
  end

  @doc """
  Atomically reload, validate, and deliver one live MTT queue message.

  The row lock makes duplicate queue deliveries safe across consumers and
  application nodes. Provider delivery happens while the lock is held so a
  second consumer cannot pass the unsent check concurrently.
  """
  def deliver_queued_message(message_id, target_id) do
    Repo.transaction(fn ->
      message =
        from(m in Message,
          where: m.id == ^message_id and m.sent == false,
          lock: "FOR UPDATE SKIP LOCKED"
        )
        |> Repo.one()
        |> case do
          nil ->
            nil

          message ->
            Repo.preload(message,
              target: [:emails, campaign: [:mtt, org: :email_backend]],
              message_content: [],
              action: [:supporter, action_page: :org]
            )
        end

      validate_and_deliver(message, target_id)
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  defp validate_and_deliver(nil, _target_id), do: :ignore

  defp validate_and_deliver(message, target_id) do
    campaign = message.target.campaign
    org = campaign.org

    result =
      cond do
        message.target_id != target_id ->
          {:discard, :target_mismatch}

        message.action.testing ->
          {:discard, :testing_action}

        message.action.processing_status != :delivered ->
          {:discard, :action_not_delivered}

        campaign.status != :live ->
          {:discard, :campaign_inactive}

        is_nil(campaign.mtt) ->
          {:discard, :mtt_missing}

        DateTime.compare(DateTime.utc_now(), campaign.mtt.end_at) != :lt ->
          {:discard, :mtt_ended}

        Proca.Server.MTT.mode() != :enabled ->
          {:discard, :mtt_disabled}

        is_nil(org.email_backend) ->
          {:discard, :email_backend_missing}

        not Enum.any?(message.target.emails, &(&1.email_status in [:active, :none])) ->
          {:discard, :no_sendable_email}

        true ->
          deliver_message(message.target, message)
      end

    case result do
      {:discard, reason} ->
        emit_delivery(:discarded,
          org_id: org.id,
          campaign_id: campaign.id,
          drip_delivery: campaign.mtt && campaign.mtt.drip_delivery,
          reason: reason
        )

      _ ->
        :ok
    end

    result
  end

  def get_pending_messages(target_id, max_emails_per_hour, sent \\ false, testing \\ false) do
    q = query_emails_to_send(target_id, sent, testing)

    case max_emails_per_hour do
      :all ->
        q

      _ ->
        q
        |> limit(^max_emails_per_hour)
    end
    |> Repo.all(prepare: :unnamed)
  end

  def delete_old_test_emails do
    Repo.delete_all(query_test_emails_to_delete(), timeout: :timer.seconds(30))
  end

  defp query_test_emails_to_delete() do
    recent = DateTime.utc_now() |> DateTime.add(@recent_test_messages, :second)

    from m in Message,
      join: a in assoc(m, :action),
      where:
        a.processing_status == :delivered and a.testing and m.sent and a.inserted_at < ^recent
  end

  @doc """
  Send the test emails of a freshly delivered testing action, for all its
  targets. Invoked by `Proca.Stage.MTT` when `Proca.Stage.Processing` pushes
  the confirm-time event. Idempotent - only unsent messages are picked up.
  No dupe_rank filter: it is not computed yet at confirm time and does not
  matter for test sends.
  """
  def deliver_test_mails(action_id) do
    Repo.transaction(fn ->
      Ecto.Adapters.SQL.query!(Repo, "SELECT pg_advisory_xact_lock($1)", [action_id])

      messages =
        from(m in Message,
          join: a in assoc(m, :action),
          where:
            a.id == ^action_id and a.testing == true and a.processing_status == :delivered and
              m.sent == false,
          order_by: [asc: m.id],
          preload: [target: :emails, message_content: [], action: [:supporter, action_page: :org]]
        )
        |> Repo.all()

      case messages do
        [] ->
          :ok

        [first | _] ->
          case get_target(first.target_id) do
            nil -> {:error, :target_unavailable}
            target -> deliver_messages(target, messages)
          end
      end
    end)
    |> case do
      {:ok, result} -> result
      {:error, reason} -> {:error, reason}
    end
  end

  def deliver_messages(target, msgs) do
    {_cancelled, msgs} = Enum.split_with(msgs, &Message.cancel_if_empty/1)

    action_pages_ids =
      msgs
      |> Enum.map(fn m -> m.action.action_page_id end)

    action_pages =
      ActionPage.all(preload: [:org], by_ids: action_pages_ids)
      |> Enum.into(%{})

    msgs_per_locale = Enum.group_by(msgs, &(&1.target.locale || @default_locale))

    target_locales = Enum.uniq(Map.keys(msgs_per_locale))

    Sentry.Context.set_extra_context(%{
      campaign_id: target.campaign.id,
      campaign_name: target.campaign.name,
      org_id: target.campaign.org.id
    })

    templates =
      Enum.map(target_locales, fn locale ->
        case EmailTemplateDirectory.by_name_reload(
               target.campaign.org,
               target.campaign.mtt.message_template,
               locale
             ) do
          {:ok, t} ->
            {locale, t}

          err when err in [:not_found] ->
            {locale, nil}
        end
      end)
      |> Enum.into(%{})

    Enum.reduce_while(msgs_per_locale, :ok, fn {locale, locale_messages}, :ok ->
      [representative | _] = locale_messages
      Sentry.Context.set_extra_context(%{action_id: representative.action_id})

      email =
        representative
        |> make_email(test_email: target.campaign.mtt.test_email)
        |> EmailMerge.put_action_page(action_pages[representative.action.action_page_id])
        |> EmailMerge.put_campaign(target.campaign)
        |> EmailMerge.put_action(representative.action)
        |> EmailMerge.put_target(representative.target)
        |> EmailMerge.put_files(resolve_files(target.campaign.org, representative.files))
        |> put_message_content(
          change_test_subject(representative.message_content, true),
          templates[locale]
        )

      case EmailBackend.deliver([email], target.campaign.org, templates[locale]) do
        :ok ->
          Message.mark_all(locale_messages, :sent)

          emit_delivery(:sent,
            kind: :test,
            org_id: target.campaign.org.id,
            campaign_id: target.campaign.id,
            drip_delivery: target.campaign.mtt.drip_delivery
          )

          {:cont, :ok}

        {:error, statuses} ->
          Logger.error("MTT test failed to send: #{inspect(statuses)}")

          emit_delivery(:retry,
            kind: :test,
            org_id: target.campaign.org.id,
            campaign_id: target.campaign.id,
            drip_delivery: target.campaign.mtt.drip_delivery,
            reason: :provider
          )

          {:halt, {:error, {:provider, statuses}}}
      end
    end)
  end

  def deliver_message(target, msg) do
    if Message.cancel_if_empty(msg) do
      :ok
    else
      email_to =
        if msg.action.testing do
          :testing
        else
          Enum.find(msg.target.emails, &(&1.email_status in [:active, :none]))
        end

      if is_nil(email_to) do
        {:discard, :no_sendable_email}
      else
        do_deliver_message(target, msg)
      end
    end
  end

  defp do_deliver_message(target, msg) do
    :telemetry.execute(
      [:proca, :mtt_new, :deliver_message],
      %{},
      %{target_id: target.id}
    )

    locale = target.locale || @default_locale

    template =
      case EmailTemplateDirectory.by_name_reload(
             target.campaign.org,
             target.campaign.mtt.message_template,
             locale
           ) do
        {:ok, template} -> template
        _ -> nil
      end

    Sentry.Context.set_extra_context(%{
      campaign_id: target.campaign.id,
      campaign_name: target.campaign.name,
      org_id: target.campaign.org.id,
      action_id: msg.action_id
    })

    message_content = change_test_subject(msg.message_content, msg.action.testing)

    message =
      msg
      |> make_email(
        test_email: target.campaign.mtt.test_email,
        cc_recipients: cc_recipients(target.campaign, msg.action.supporter)
      )
      |> EmailMerge.put_action_page(msg.action.action_page)
      |> EmailMerge.put_campaign(target.campaign)
      |> EmailMerge.put_action(msg.action)
      |> EmailMerge.put_target(msg.target)
      |> EmailMerge.put_files(resolve_files(target.campaign.org, msg.files))
      |> put_message_content(message_content, template)

    case EmailBackend.deliver(message, target.campaign.org, template) do
      :ok ->
        if message.private.email_id do
          TargetEmail.mark_one(message.private.email_id, :active)
        end

        Message.mark_one(msg, :sent)

        emit_delivery(:sent,
          org_id: target.campaign.org.id,
          campaign_id: target.campaign.id,
          drip_delivery: target.campaign.mtt.drip_delivery
        )

      {:error, statuses} ->
        Logger.error("MTT failed to send message #{msg.id}: #{inspect(statuses)}")

        emit_delivery(:retry,
          org_id: target.campaign.org.id,
          campaign_id: target.campaign.id,
          drip_delivery: target.campaign.mtt.drip_delivery,
          reason: :provider
        )

        {:error, {:provider, statuses}}
    end
  end

  def max_emails_per_hour(campaign = %Campaign{mtt: %{max_emails_per_hour: nil, timezone: _}}) do
    limit_emails_per_hour =
      Application.get_env(:proca, Proca.Server.MTTScheduler)
      |> Access.get(:max_emails_per_hour, 30)

    mtt = %{campaign.mtt | max_emails_per_hour: limit_emails_per_hour}
    campaign = %{campaign | mtt: mtt}

    max_emails_per_hour(campaign)
  end

  def max_emails_per_hour(%Campaign{
        mtt: %{max_emails_per_hour: max_emails_per_hour, timezone: timezone}
      }) do
    Application.get_env(:proca, Proca.Server.MTTScheduler)
    |> Access.get(:messages_ratio_per_hour)
    |> Access.get(DateTime.now!(timezone).hour)
    |> Kernel.*(max_emails_per_hour)
    |> trunc()
    |> max(1)
  end

  def dupe_rank() do
    # Fast check if any messages need ranking — the partial index
    # on messages(dupe_rank) WHERE dupe_rank IS NULL makes this instant.
    if Repo.aggregate(from(m in Message, where: is_nil(m.dupe_rank)), :count) == 0 do
      :ok
    else
      sql = """
      UPDATE messages
      SET dupe_rank = ranked.dupe_rank
      FROM
      (
        SELECT
          m.id,
          rank() OVER (PARTITION BY s.fingerprint, m.target_id ORDER BY a.inserted_at) - 1 as dupe_rank
        FROM messages m
          JOIN actions a ON m.action_id = a.id
          JOIN supporters s ON a.supporter_id = s.id
        WHERE m.dupe_rank is NULL
          AND a.processing_status = 4
          AND s.processing_status = 3
      ) ranked
      WHERE messages.id = ranked.id;
      """

      Ecto.Adapters.SQL.query(Proca.Repo, sql)
    end
  end

  defp query_emails_to_send(target_id, sent, testing) do
    sent = List.wrap(sent)

    sent_dynamic =
      case sent do
        [val] -> dynamic([m], m.sent == ^val)
        vals -> dynamic([m], m.sent in ^vals)
      end

    base =
      from(
        m in Proca.Action.Message,
        join: t in assoc(m, :target),
        join: a in assoc(m, :action),
        join: s in assoc(a, :supporter),
        join: ap in assoc(a, :action_page),
        join: mc in assoc(m, :message_content),
        where:
          m.target_id == ^target_id and
            a.processing_status == :delivered and
            a.testing == ^testing and
            m.dupe_rank == 0,
        order_by: [asc: m.id],
        distinct: m.id,
        preload: [
          target: :emails,
          message_content: mc,
          action: {a, [:supporter, :action_page]}
        ]
      )

    from(m in base, where: ^sent_dynamic)
  end

  def make_email(
        message = %{id: message_id, action: %{supporter: supporter, testing: is_test}},
        opts \\ []
      ) do
    email_to =
      if is_test do
        %Proca.TargetEmail{email: supporter.email, email_status: :none}
      else
        Enum.find(message.target.emails, fn email_to ->
          email_to.email_status in [:active, :none]
        end)
      end

    # Re-use logic to convert first_name, last_name to name
    supporter_name =
      Proca.Contact.Input.Contact.normalize_names(Map.from_struct(supporter))[:name]

    email =
      EmailBackend.make_email(
        {message.target.name, email_to.email},
        {:mtt, message_id},
        email_to.id
      )
      |> Email.from({supporter_name, supporter.email})
      |> maybe_add_cc(opts[:test_email], is_test)

    Enum.reduce(opts[:cc_recipients] || [], email, &Email.cc(&2, &1))
  end

  # cc list for live messages, from the campaign's MTT settings
  def cc_recipients(%{mtt: %{cc_sender: true, cc_contacts: contacts}}, supporter),
    do: [supporter.email | contacts]

  def cc_recipients(%{mtt: %{cc_contacts: contacts}}, _supporter), do: contacts

  defp maybe_add_cc(email, cc, true), do: Email.cc(email, cc)
  defp maybe_add_cc(email, _cc, false), do: email

  defp resolve_files(org, file_keys) do
    case Proca.Service.fetch_files(org, file_keys) do
      {:ok, files} -> files
      {:error, _reason, partial} -> partial
    end
  end

  defp put_message_content(
         email = %Email{},
         %Proca.Action.MessageContent{subject: subject, body: body},
         _template = nil
       ) do
    # Render the raw body
    target_assigns = camel_case_keys(%{target: email.assigns[:target]})

    Sentry.Context.set_extra_context(%{
      template_id: nil,
      template_name: nil,
      message_subject: subject,
      message_body: body
    })

    body =
      body
      |> EmailTemplate.compile_string()
      |> EmailTemplate.render_string(target_assigns)

    subject =
      subject
      |> EmailTemplate.compile_string()
      |> EmailTemplate.render_string(target_assigns)

    html_body = EmailMerge.plain_to_html(body)

    email
    |> Email.html_body(html_body)
    |> Email.text_body(body)
    |> Email.subject(subject)
  end

  defp put_message_content(
         email = %Email{},
         %Proca.Action.MessageContent{subject: subject, body: body},
         _template
       ) do
    html_body = EmailMerge.plain_to_html(body)

    email
    |> Email.assign(:body, html_body)
    |> Email.assign(:subject, subject)
  end

  defp change_test_subject(message_content, false), do: message_content

  defp change_test_subject(message_content = %{subject: subject}, true),
    do: Map.put(message_content, :subject, "[TEST] " <> subject)
end
