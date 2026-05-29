defmodule Proca.Supporter.ConfirmReminder do
  @moduledoc """
  Sends confirmation reminder emails to supporters stuck in :confirming state.

  Per-org config (stored in org.config["reminder"]):
    - "enabled"              - must be true to send reminders (opt-in, default disabled)
    - "reminder_delays_days" - list of delays (in days from inserted_at) at which to
                               send each reminder. Default [2, 5] sends a first reminder
                               2 days after signup and a second at 5 days.
    - "max_age_days"         - actions older than this (from inserted_at) are ignored;
                               prevents reminding supporters who signed up long ago.
                               Default 30.

  Timing is tracked via action.reminder_count. Each sent reminder increments the
  counter. reminder_count == N means N reminders have been sent; the action is due
  for reminder N when inserted_at is older than reminder_delays_days[N] and
  reminder_count == N. When all delays are exhausted no further reminders are sent.
  """

  import Ecto.Query
  require Logger

  alias Proca.{Repo, Org, Action, Supporter}
  alias Proca.Service.{EmailBackend, EmailMerge, EmailTemplateDirectory}
  alias Proca.Stage.{EmailSupporter, Support}
  alias Swoosh.Email

  @default_reminder_delays [2]
  @default_max_age_days 30

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
      delays = org_reminder_delays(org)
      max_age = org_max_age_days(org)
      {org, due_actions(org.id, delays, max_age)}
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
      preload: [email_backend: :org]
    )
    |> Repo.all()
  end

  defp process_org(org) do
    if reminder_enabled?(org) do
      delays = org_reminder_delays(org)
      max_age = org_max_age_days(org)
      actions = due_actions(org.id, delays, max_age)

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

  defp due_actions(org_id, reminder_delays, max_age_days) do
    reminder_delays
    |> Enum.with_index()
    |> Enum.flat_map(fn {delay_days, count} ->
      query_due_actions(org_id, count, delay_days, max_age_days)
    end)
  end

  defp query_due_actions(org_id, reminder_count, delay_days, max_age_days) do
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
        where: a.reminder_count == ^reminder_count,
        where: a.inserted_at < ago(^delay_days, "day"),
        where: a.inserted_at > ago(^max_age_days, "day"),
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
    tmpl_name =
      ap.supporter_confirm_template ||
        ap.campaign.supporter_confirm_template ||
        org.supporter_confirm_template

    case EmailTemplateDirectory.by_name_reload(org, tmpl_name, ap.locale) do
      {:ok, tmpl} ->
        recipients =
          Enum.map(actions, fn action ->
            data = Support.action_data(action, :supporter_confirm)

            EmailSupporter.make(data)
            |> add_reminder_links()
          end)

        case EmailBackend.deliver(recipients, org, tmpl) do
          :ok ->
            Enum.each(actions, &mark_sent/1)

          {:error, statuses} ->
            Enum.zip(actions, statuses)
            |> Enum.each(fn
              {action, :ok} ->
                mark_sent(action)

              {action, {:error, reason}} ->
                Logger.error(
                  "ConfirmReminder: failed for action #{action.id}: #{inspect(reason)}"
                )
            end)
        end

      :not_found ->
        Logger.warning(
          "ConfirmReminder: template #{tmpl_name} not found for org #{org.name}"
        )
    end
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
    Repo.update_all(
      from(a in Action, where: a.id == ^action_id),
      inc: [reminder_count: 1]
    )
  end

  defp reminder_enabled?(%Org{config: config}) do
    get_in(config, ["reminder", "enabled"]) == true
  end

  defp org_reminder_delays(%Org{config: config}) do
    case get_in(config, ["reminder", "reminder_delays_days"]) do
      nil -> @default_reminder_delays
      list when is_list(list) -> list
    end
  end

  defp org_max_age_days(%Org{config: config}) do
    case get_in(config, ["reminder", "max_age_days"]) do
      nil -> @default_max_age_days
      v when is_integer(v) -> v
    end
  end
end
