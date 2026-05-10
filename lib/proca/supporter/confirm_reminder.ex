defmodule Proca.Supporter.ConfirmReminder do
  @moduledoc """
  Sends confirmation reminder emails to supporters stuck in :confirming state.

  Per-org config (stored in org.config["reminder"]):
    - "delay_days" - days to wait before sending first reminder, and between
                     subsequent reminders (default 2)

  Timing is tracked via action.updated_at. When a reminder is sent the action's
  updated_at is touched, so the next reminder is spaced by delay_days from that
  point. supporter_confirm can be enabled at the org or campaign level.
  """

  import Ecto.Query
  require Logger

  alias Proca.{Repo, Org, Campaign, Action, Supporter}
  alias Proca.Service.{EmailBackend, EmailMerge, EmailTemplateDirectory}
  alias Proca.Stage.{EmailSupporter, Support}
  alias Swoosh.Email

  @default_delay_days 2

  def run do
    orgs_with_confirm()
    |> Enum.each(&process_org/1)
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
    delay_days = org_delay_days(org)
    actions = due_actions(org.id, delay_days)

    if actions != [] do
      Logger.info(
        "ConfirmReminder: sending #{length(actions)} reminders for org #{org.name}"
      )

      send_for_org(org, actions)
    end
  end

  defp due_actions(org_id, delay_days) do
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
    now = DateTime.truncate(DateTime.utc_now(), :second)

    Repo.update_all(
      from(a in Action, where: a.id == ^action_id),
      set: [updated_at: now]
    )
  end

  defp org_delay_days(%Org{config: config}) do
    case get_in(config, ["reminder", "delay_days"]) do
      nil -> @default_delay_days
      v when is_integer(v) -> v
      v when is_binary(v) -> String.to_integer(v)
    end
  end
end
