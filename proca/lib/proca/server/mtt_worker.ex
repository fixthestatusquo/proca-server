defmodule Proca.Server.MTTWorker do
  alias Proca.Repo
  import Ecto.Query

  alias Proca.Service.{EmailRecipient, EmailBackend, EmailTemplate}

  def process_mtt_campaign(campaign) do
    if within_sending_time(campaign) do
      cycles_till_end = calculate_cycles(campaign)
      target_ids = get_sendable_targets(campaign.id)
      emails_to_send = get_emails_to_send(target_ids, cycles_till_end)

      send_emails(campaign, emails_to_send)
    else
      IO.puts("Campaign with ID #{campaign.id} not in sending time")
    end
  end

  defp get_sendable_targets(campaign_id) do
    targets =
      from(t in Proca.Target,
        join: c in Proca.Campaign,
        on: c.id == ^campaign_id,
        join: te in Proca.TargetEmail,
        on: te.target_id == t.id,
        where: te.email_status == :none,
        distinct: t.id,
        select: t.id
      )
    |> Repo.all()
  end

  def calculate_cycles(campaign) do
    time_now = DateTime.utc_now()
    end_time = campaign.mtt.end_at

    cycles_per_day = calculate_cycles(campaign.mtt.start_at, campaign.mtt.end_at)
    cycles_today = calculate_cycles(Time.utc_now(), campaign.mtt.end_at)
    days_left = Date.diff(campaign.mtt.end_at, Date.utc_today())

    (days_left * cycles_per_day) + cycles_today
  end

  def within_sending_time(campaign) do
    start_time = DateTime.to_time(campaign.mtt.start_at)
    end_time = DateTime.to_time(campaign.mtt.end_at)
    current_time = Time.utc_now()

    # Time.compare returns :gt or :lt or :eq, checking if current_time :gt start_time
    # and end_time :gt current_time are the same should work just as well
    Time.compare(current_time, start_time) == Time.compare(end_time, current_time)
  end

  def get_emails_to_send(target_ids, cycles_till_end) do
    List.flatten(Enum.map(target_ids, fn target_id ->
      get_emails_for_target(target_id, cycles_till_end)
    end))
  end

  def get_emails_for_target(target_id, cycles_till_end) do
    emails =
      from(m in Proca.Action.Message,
        join: t in Proca.Target,
        on: m.target_id == t.id,
        join: a in Proca.Action,
        on: m.action_id == a.id,
        where: a.processing_status == :accepted and m.delivered == false and m.target_id == ^target_id,
        order_by: m.id,
        preload: [:message_content, :target, [target: :emails]]
      )
    |> Repo.all()

    emails_to_send = Integer.floor_div(Enum.count(emails), cycles_till_end)
    Enum.take(emails, emails_to_send)
  end

  defp send_emails(campaign, emails) do
    recipients = emails
    |> Enum.map(&prepare_recipient/1)

    org = Proca.Org.get_by_id(campaign.org_id, [:email_backend])
    tmpl = %EmailTemplate{ref: campaign.mtt.message_template}

    EmailBackend.deliver(recipients, org, tmpl)
  end

  defp prepare_recipient(email) do
    email_to = Enum.find(email.target.emails, fn email_to ->
      email_to.email_status == :none
    end)
    %EmailRecipient{
      first_name: email.target.name,
      email: email_to.email,
      fields: %{
        subject: email.message_content.subject,
        body: email.message_content.body
      },
      email_from: email.email_from
    }
  end

  defp calculate_cycles(start_time, end_time) do
    mins_per_cycles = Application.get_env(:proca, Proca)[:mtt_cycle_time]
    time_diff = Integer.floor_div(Time.diff(end_time, start_time, :second), 60)

    Integer.floor_div(time_diff, mins_per_cycles)
  end
end
