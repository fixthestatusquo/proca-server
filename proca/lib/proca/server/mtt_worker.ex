defmodule Proca.Server.MTTWorker do
  def process_mtt_campaign(campaign) do
    if within_sending_time(campaign) do
      emails_count_to_send = calculate_emails_to_send(campaign)
      emails_to_send = get_emails_to_send(campaign, emails_count_to_send)
      IO.inspect(campaign)

    else
      IO.puts("Campaign with ID #{campaign.id} not in sending time")
    end
  end

  defp within_sending_time(campaign) do
    start_time = DateTime.to_time(campaign.mtt.start_at)
    end_time = DateTime.to_time(campaign.mtt.end_at)
    current_time = Time.utc_now()

    # Time.compare returns :gt or :lt or :eq, checking if current_time :gt start_time
    # and end_time :gt current_time are the same should work just as well
    Time.compare(current_time, start_time) == Time.compare(end_time, current_time)
  end

  defp calculate_emails_to_send(campaign) do
    # Get Sending Rate
    # Divide Sending Rate by 60 to get minute rate
  end

  defp get_emails_to_send(campaign, emails_count_to_send) do
    # Pull actions with processed, and no message field
  end
end
