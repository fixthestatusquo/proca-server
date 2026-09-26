defmodule Proca.Supporter.ConfirmReminder do
  @moduledoc """
  Sends confirmation reminder emails to supporters stuck in :confirming state.

  Per-org config (stored in org.config["reminder"]):
    - "enabled"    - must be true to send reminders (opt-in, default disabled)
    - "delay_days" - days to wait before sending first reminder, and between
                     subsequent reminders (default 2)
    - "max_count"  - maximum number of reminders to send per action (default 3)

  Timing is tracked via action.updated_at. When a reminder is sent the action's
  updated_at is touched, so the next reminder is spaced by delay_days from that
  point. The total reminder window is capped at delay_days * max_count days from
  action.inserted_at, so no migration is needed to track reminder count.
  supporter_confirm can be enabled at the org or campaign level.
  """

  import Ecto.Query
  require Logger

  alias Proca.{Repo, Org, Campaign, Action, Supporter}
  alias Proca.Service.{EmailBackend, EmailMerge, EmailTemplateDirectory}
  alias Proca.Stage.{EmailSupporter, Support}
  alias Swoosh.Email

  @default_delay_days 2
  @default_max_count 3

  def run do
    orgs_with_confirm()
    |> Enum.each(&process_org/1)
  end

  @doc """
  Returns `{org, [action]}` pairs that would receive reminders on the next run.
  Used by the mix task dry-run.
  """
  def list_due do
    orgs_with_confirm()
    |> Enum.filter(&reminder_enabled?/1)
    |> Enum.map(fn org ->
      delay_days = org_delay_days(org)
      max_count = org_max_count(org)
      {org, due_actions(org.id, delay_days, max_count)}
    end)
    |> Enum.reject(fn {_org, actions} -> actions == [] end)
  end

  defp orgs_with_confirm do
    from(o in Org,
      left_join: c in assoc(o, :campaigns),
      where: o.supporter_confirm == true or c.supporter_confirm == true,
      where: not is_nil(o.email_backend_id),
      where: not is_nil(o.email_from),
      distinct: true,
      preload: [:email_backend, :transactional_email_backend]
    )
    |> Repo.all()
  end

  defp process_org(org) do
    if reminder_enabled?(org) do
      delay_days = org_delay_days(org)
      max_count = org_max_count(org)
      actions = due_actions(org.id, delay_days, max_count)

      if actions != [] do
        Logger.info(
          "ConfirmReminder: sending #{length(actions)} reminders for org #{org.name}"
        )

        send_for_org(org, actions)
      end
    else
      Logger.debug("ConfirmReminder: skipping org #{org.name} (reminder not enabled in config)")
    end
  end

  defp due_actions(org_id, delay_days, max_count) do
    max_days = delay_days * max_count

    action_ids =
      from(a in Action,
        join: s in assoc(a, :supporter),
        join: ap in assoc(a, :action_page),
        join: c in assoc(a, :campaign),
        join: o in assoc(ap, :org),
        where: ap.org_id == ^org_id,
        where: o.supporter_confirm == true or c.supporter_confirm == true,
        where: s.processing_status == :confirming,
        where: a.with_consent == true,
        where: a.updated_at < ago(^delay_days, "day"),
        where: a.inserted_at > ago(^max_days, "day"),
        select: a.id
      )
      |> Repo.all()

    from(a in Action,
      where: a.id in ^action_ids,
      preload: [
        action_page: [:campaign, :org],
        supporter: [contacts: [:public_key, :sign_key, :org]],
        campaign: [],
        source: []
      ]
    )
    |> Repo.all()
  end

  defp send_for_org(org, actions) do
    actions
    |> Enum.group_by(& &1.action_page_id)
    |> Enum.each(fn {_ap_id, ap_actions} ->
      ap = hd(ap_actions).action_page
      send_batch(org, ap, ap_actions)
    end)
  end

  defp send_batch(org, ap, actions) do
    org = Org.for_transactional_email(org, length(actions))

    tmpl_name =
      ap.supporter_confirm_template ||
        ap.campaign.supporter_confirm_template ||
        org.supporter_confirm_template

    case EmailTemplateDirectory.by_name_reload(org, tmpl_name, ap.locale) do
      {:ok, tmpl} ->
        Logger.info(
          "ConfirmReminder: sending #{length(actions)} email(s) org=#{org.name} template=#{tmpl_name}"
        )

        recipients =
          Enum.map(actions, fn action ->
            data = Support.action_data(action, :supporter_confirm)

            EmailSupporter.make(data)
            |> add_reminder_links()
          end)

        case EmailBackend.deliver(recipients, org, tmpl) do
          :ok ->
            Enum.each(actions, &mark_sent/1)

            Logger.info(
              "ConfirmReminder: done org=#{org.name} template=#{tmpl_name} sent=#{length(actions)} failed=0"
            )

          {:error, statuses} ->
            failed =
              Enum.zip(actions, statuses)
              |> Enum.filter(fn
                {action, :ok} ->
                  mark_sent(action)
                  false

                {action, {:error, reason}} ->
                  Logger.error(
                    "ConfirmReminder: failed for action #{action.id}: #{inspect(reason)}"
                  )

                  true
              end)
              |> length()

            Logger.info(
              "ConfirmReminder: done org=#{org.name} template=#{tmpl_name} sent=#{length(actions) - failed} failed=#{failed}"
            )
        end

      :not_found ->
        Logger.warning(
          "ConfirmReminder: template #{tmpl_name} not found for org #{org.name}"
        )
    end
  end

  @doc """
  Ad-hoc lookup of unconfirmed actions, bypassing the reminder.enabled/delay_days/
  max_count gating used by run/0. Used to recover from lost transactional emails.

  opts:
    - :org (required) - org name
    - :campaign (optional) - campaign name, restricts to that campaign
    - :since_days (optional) - only actions taken in the last N days
  """
  def list_unconfirmed(opts) do
    org =
      from(o in Org,
        where: o.name == ^Keyword.fetch!(opts, :org),
        preload: [:email_backend, :transactional_email_backend]
      )
      |> Repo.one!()

    campaign_id =
      case opts[:campaign] do
        nil -> nil
        name -> Repo.get_by!(Campaign, name: name).id
      end

    query =
      from(a in Action,
        join: s in assoc(a, :supporter),
        join: ap in assoc(a, :action_page),
        where: ap.org_id == ^org.id,
        where: s.processing_status == :confirming,
        where: a.with_consent == true,
        preload: [
          action_page: [:campaign, :org],
          supporter: [contacts: [:public_key, :sign_key, :org]],
          campaign: [],
          source: []
        ]
      )

    query = if campaign_id, do: from(a in query, where: a.campaign_id == ^campaign_id), else: query

    query =
      if opts[:since_days],
        do: from(a in query, where: a.inserted_at >= ago(^opts[:since_days], "day")),
        else: query

    {org, Repo.all(query)}
  end

  @doc """
  Resends the supporter-confirm email for the actions matched by list_unconfirmed/1.
  """
  def resend_unconfirmed(opts) do
    {org, actions} = list_unconfirmed(opts)

    Logger.info(
      "ConfirmReminder: resend_unconfirmed org=#{opts[:org]} campaign=#{opts[:campaign]} since_days=#{opts[:since_days]} count=#{length(actions)}"
    )

    if actions != [] do
      send_for_org(org, actions)
    end

    {org, actions}
  end

  defp add_reminder_links(%Email{assigns: %{ref: ref, action_id: action_id}} = email) do
    confirm_link = Support.supporter_link(action_id, ref, :confirm, reminder: "1")
    reject_link = Support.supporter_link(action_id, ref, :reject, reminder: "1")

    EmailMerge.put_assigns(email,
      confirm_link: confirm_link,
      doi_link: confirm_link,
      reject_link: reject_link
    )
  end

  defp mark_sent(%Action{id: action_id}) do
    now = DateTime.truncate(DateTime.utc_now(), :second)

    Repo.update_all(
      from(a in Action, where: a.id == ^action_id),
      set: [updated_at: now]
    )
  end

  defp reminder_enabled?(%Org{config: config}) do
    get_in(config, ["reminder", "enabled"]) == true
  end

  defp org_delay_days(%Org{config: config}) do
    case get_in(config, ["reminder", "delay_days"]) do
      nil -> @default_delay_days
      v when is_integer(v) -> v
      v when is_binary(v) -> String.to_integer(v)
    end
  end

  defp org_max_count(%Org{config: config}) do
    case get_in(config, ["reminder", "max_count"]) do
      nil -> @default_max_count
      v when is_integer(v) -> v
      v when is_binary(v) -> String.to_integer(v)
    end
  end
end
