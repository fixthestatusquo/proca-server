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

  def get_pending_messages(target_id, max_emails_per_hour, sent \\ false, testing \\ false) do
    q = query_emails_to_send(target_id, sent, testing)

    case max_emails_per_hour do
      :all ->
        q

      _ ->
        q
        |> limit(^max_emails_per_hour)
    end
    |> Repo.all()
  end

  def process_test_mails(target) do
    Repo.delete_all(query_test_emails_to_delete())

    test_emails = get_pending_test_messages(target.id)

    if target.campaign.org.email_backend != nil do
      deliver_messages(target, test_emails)
      {target.id, length(test_emails)}
    else
      {target.id, 0}
    end
  end

  def get_pending_test_messages(target_id) do
    recent =
      DateTime.utc_now()
      |> DateTime.add(@recent_test_messages, :second)

    query_emails_to_send(target_id, false, true)
    |> where([m, t, a], a.inserted_at >= ^recent)
    |> order_by([m], asc: m.id)
    |> Repo.all()
  end

  def deliver_messages(target, msgs) do
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

    for {locale, msgs} <- msgs_per_locale do
      # for testing, just send the first one
      {msgs, testing} = Enum.split(msgs, 1)

      Message.mark_all(testing, :delivered)
      Message.mark_all(testing, :sent)

      for chunk <- Enum.chunk_every(msgs, EmailBackend.batch_size(target.campaign.org)) do
        batch =
          for e <- chunk do
            Sentry.Context.set_extra_context(%{action_id: e.action_id})

            message_content = change_test_subject(e.message_content, e.action.testing)

            e
            |> make_email(target.campaign.mtt.test_email)
            |> EmailMerge.put_action_page(action_pages[e.action.action_page_id])
            |> EmailMerge.put_campaign(target.campaign)
            |> EmailMerge.put_action(e.action)
            |> EmailMerge.put_target(e.target)
            |> EmailMerge.put_files(resolve_files(target.campaign.org, e.files))
            |> put_message_content(message_content, templates[locale])
          end

        case EmailBackend.deliver(batch, target.campaign.org, templates[locale]) do
          :ok ->
            batch
            |> Enum.flat_map(fn m ->
              case m.private.email_id do
                nil -> []
                id -> [id]
              end
            end)
            |> TargetEmail.mark_all(:active)

            Message.mark_all(chunk, :sent)

          {:error, statuses} ->
            Logger.error("MTT failed to send, statuses: #{inspect(statuses)}")

            Enum.zip(chunk, statuses)
            |> Enum.filter(fn
              {_, :ok} -> true
              _ -> false
            end)
            |> Enum.map(fn {m, _} -> m end)
            |> Message.mark_all(:sent)
        end
      end
    end
  end

  def deliver_message(target, msg) do
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
      |> make_email(target.campaign.mtt.test_email)
      |> EmailMerge.put_action_page(msg.action.action_page)
      |> EmailMerge.put_campaign(target.campaign)
      |> EmailMerge.put_action(msg.action)
      |> EmailMerge.put_target(msg.target)
      |> EmailMerge.put_files(resolve_files(target.campaign.org, msg.files))
      |> put_message_content(message_content, template)

    case EmailBackend.deliver(message, target.campaign.org, template) do
      :ok ->
        message.private.email_id
        |> TargetEmail.mark_one(:active)

        Message.mark_one(msg, :sent)

      {:error, statuses} ->
        Logger.error("MTT failed to send, statuses: #{inspect(statuses)}")

        if Enum.member?(statuses, &(&1 == :ok)) do
          msg
          |> Message.mark_one(:sent)
        end
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
        mtt: %{max_emails_per_hour: max_emails_per_hour, timezone: timezone, end_at: end_at}
      }) do
    now = %{DateTime.utc_now() | minute: 0, second: 0, microsecond: {0, 0}}

    if DateTime.diff(end_at, now, :hour) > 1 do
      Application.get_env(:proca, Proca.Server.MTTScheduler)
      |> Access.get(:messages_ratio_per_hour)
      |> Access.get(DateTime.now!(timezone).hour)
      |> Kernel.*(max_emails_per_hour)
      |> trunc()
      |> max(1)
    else
      :all
    end
  end

  def dupe_rank() do
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

  defp query_emails_to_send(target_id, sent, testing) do
    sent = List.wrap(sent)

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
          m.sent in ^sent and
          m.dupe_rank == 0 and
          mc.subject != "" and mc.body != "",
      order_by: [asc: m.id],
      distinct: m.id,
      preload: [
        target: :emails,
        message_content: mc,
        action: {a, [:supporter, :action_page]}
      ]
    )
  end

  defp query_test_emails_to_delete() do
    recent = DateTime.utc_now() |> DateTime.add(@recent_test_messages, :second)

    from m in Message,
      join: a in assoc(m, :action),
      where: a.processing_status == :delivered and a.testing and a.inserted_at < ^recent
  end

  def make_email(
        message = %{id: message_id, action: %{supporter: supporter, testing: is_test}},
        test_email
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

    EmailBackend.make_email(
      {message.target.name, email_to.email},
      {:mtt, message_id},
      email_to.id
    )
    |> Email.from({supporter_name, supporter.email})
    |> maybe_add_cc(test_email, is_test)
  end

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
