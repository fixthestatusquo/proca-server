defmodule Proca.Server.MTTWorker do
  alias Proca.Repo
  import Ecto.Query

  alias Swoosh.Email
  alias Proca.Action
  alias Proca.Service.{EmailBackend, EmailTemplate}

  import Logger

  def process_mtt_campaign(campaign) do
    if within_sending_time(campaign) do
      cycles_till_end = calculate_cycles(campaign)
      target_ids = get_sendable_targets(campaign.id)
      emails_to_send = get_emails_to_send(target_ids, cycles_till_end)

      send_emails(campaign, emails_to_send)
    else
      debug("Campaign #{campaign.name} (ID #{campaign.id}) not in sending time")
    end
  end

  defp get_sendable_targets(campaign_id) do
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
    cycles_per_day = calculate_cycles(campaign.mtt.start_at, campaign.mtt.end_at)
    cycles_today = calculate_cycles(Time.utc_now(), campaign.mtt.end_at)
    days_left = Date.diff(campaign.mtt.end_at, Date.utc_today())

    days_left * cycles_per_day + cycles_today
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
    List.flatten(
      Enum.map(target_ids, fn target_id ->
        get_emails_for_target(target_id, cycles_till_end)
      end)
    )
  end

  def get_emails_for_target(target_id, cycles_till_end) do
    emails =
      from(m in Proca.Action.Message,
        join: t in Proca.Target,
        on: m.target_id == t.id,
        join: a in Proca.Action,
        on: m.action_id == a.id,
        where:
          a.processing_status == :accepted and m.delivered == false and m.target_id == ^target_id,
        order_by: m.id,
        preload: [:message_content, :target, [target: :emails], :action, [action: :supporter]]
      )
      |> Repo.all()

    emails_to_send = Integer.floor_div(Enum.count(emails), cycles_till_end)
    Enum.take(emails, emails_to_send)
  end

  defp send_emails(campaign, emails) do
    emails =
      for e <- emails do
        e
        |> prepare_recipient()
        |> put_content(e.message_content, campaign.mtt.message_template)
      end

    org = Proca.Org.get_by_id(campaign.org_id, [:email_backend])

    EmailBackend.deliver(emails, org)
  end

  defp prepare_recipient(message = %{action: %{supporter: supporter}}) do
    email_to =
      Enum.find(message.target.emails, fn email_to ->
        email_to.email_status == :none
      end)

    Email.new(
      from: {supporter.first_name, supporter.email},
      to: {message.target.name, email_to.email}
    )
  end

  # Lets handle both: 1.send with a mtt template 2. raw send the message content into subject + body
  defp put_content(
         email = %Email{},
         %Action.MessageContent{subject: subject, body: body},
         template_ref
       )
       when is_bitstring(template_ref) do
    email
    |> Email.put_private(:template, %EmailTemplate{ref: template_ref})
    |> Email.assign(:subject, subject)
    |> Email.assign(:body, body)
  end

  defp put_content(email = %Email{}, %Action.MessageContent{subject: subject, body: body}, nil) do
    # XXX should be elsewhere?
    html_body = EmailTemplate.html_from_text(body)

    Email.put_private(email, :template, %EmailTemplate{
      subject: subject,
      text: body,
      html: html_body
    })
  end

  defp calculate_cycles(start_time, end_time) do
    mins_per_cycles = Application.get_env(:proca, Proca)[:mtt_cycle_time]
    time_diff = Integer.floor_div(Time.diff(end_time, start_time, :second), 60)

    Integer.floor_div(time_diff, mins_per_cycles)
  end
end
