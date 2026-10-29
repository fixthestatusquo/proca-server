defmodule ProcaWeb.WebhookController do
  @moduledoc """
  Incoming webhook controller to process call backs from services like Mailjet, Brevo, SES, etc
  """
  use ProcaWeb, :controller

  require Logger

  alias Proca.Service.Mailjet
  alias Proca.Service.Brevo
  alias Proca.Service.SNS
  alias Proca.Service.SES

  @doc """
  Mailjet sends an array of events. Phoenx Plug wraps this in _json key because params is a map and array would break merging other params
  """
  def mailjet(conn, %{"_json" => events}) do
    for %{"event" => et} = event <- events do
      safely(:mailjet, event, fn ->
        cond do
          et in ["blocked", "spam", "unsub"] ->
            Mailjet.handle_bounce(event)

          # both hard and soft bounces; soft ones only disable the address
          # after repeated failures (see Proca.Target.handle_bounce/1)
          et == "bounce" ->
            Mailjet.handle_bounce(event)

          true ->
            Mailjet.handle_event(event)
        end
      end)
    end

    conn
    |> send_resp(:ok, "")
  end

  def mailjet(conn, event) do
    # If we receive a single event instead of list we should wrap it
    mailjet(conn, %{"_json" => [event]})
  end

  @brevo_bounce_events ~w(bounced spam unsubscribed blocked)

  def brevo(conn, event = %{"event" => et}) do
    safely(:brevo, event, fn ->
      if et in @brevo_bounce_events do
        Brevo.handle_bounce(event)
      else
        Brevo.handle_event(event)
      end
    end)

    conn |> send_resp(:ok, "")
  end

  def brevo(conn, _params) do
    conn |> send_resp(:ok, "")
  end

  @ses_bounce_events ~w(Bounce Complaint Reject)

  @doc """
  SES reports come through AWS SNS. SNS posts JSON as text/plain, so Plug does not
  parse it and we read the body ourselves. Messages not signed by AWS for one of our
  topics are refused, see Proca.Service.SNS.
  """
  def ses(conn, _params) do
    with {:ok, body, conn} <- read_body(conn),
         {:ok, %{} = msg} <- Jason.decode(body),
         :ok <- SNS.verify(msg) do
      handle_sns(msg)
      send_resp(conn, :ok, "")
    else
      # signed by AWS, so most likely our topic is missing from the allowlist.
      # error level, so it reaches Sentry
      {:error, {:topic_not_allowed, topic}} ->
        Logger.error(
          "ses webhook: refused AWS message from #{topic}, add it to SES_SNS_TOPIC_ARNS if it is ours"
        )

        send_resp(conn, :forbidden, "")

      # anyone can post junk here, so only a warning
      error ->
        Logger.warning("ses webhook: refused #{inspect(error)}")
        send_resp(conn, :forbidden, "")
    end
  end

  # sent once when the topic is subscribed to our url and added to the allowlist in config/releases.exs.
  defp handle_sns(%{"Type" => "SubscriptionConfirmation", "TopicArn" => topic} = msg) do
    case Tesla.get(msg["SubscribeURL"]) do
      {:ok, %{status: 200}} ->
        Logger.info("ses webhook: subscribed to #{topic}")

      other ->
        Logger.warning("ses webhook: cannot confirm subscription to #{topic}: #{inspect(other)}")
    end
  end

  defp handle_sns(%{"Type" => "Notification", "Message" => message}) do
    case Jason.decode(message) do
      {:ok, %{} = report} ->
        safely(:ses, report, fn ->
          if SES.event_type(report) in @ses_bounce_events do
            SES.handle_bounce(report)
          else
            SES.handle_event(report)
          end
        end)

      # eg. "Successfully validated SNS topic for Amazon SES event publishing."
      _ ->
        Logger.info("ses webhook: #{message}")
    end
  end

  defp handle_sns(%{"Type" => type, "TopicArn" => topic}) do
    Logger.info("ses webhook: #{type} for #{topic}")
  end

  # A failing event must never turn into a 500: providers retry the whole batch
  # and, after repeated errors, mark our callback URL dead and stop calling
  # (this silently disabled Mailjet bounces for a year). Report and move on.
  defp safely(provider, event, fun) do
    fun.()
  rescue
    e ->
      extra = %{
        provider: provider,
        event: event_name(provider, event),
        custom_id: custom_id(provider, event)
      }

      # warning, not error: Sentry.LoggerBackend would report an error log a second time
      Logger.warning(
        "#{provider} webhook event failed #{inspect(extra)}: #{Exception.message(e)}"
      )

      # grouped by stacktrace, so each distinct bug gets its own Sentry issue
      Sentry.capture_exception(e, stacktrace: __STACKTRACE__, extra: extra)

      :error
  end

  # report only the type and our id - the payload contains the recipient email
  defp custom_id(:mailjet, event), do: event["CustomID"]
  defp custom_id(:brevo, event), do: event["tags"]

  defp custom_id(:ses, report), do: SES.custom_id(report["mail"])

  defp event_name(:ses, report), do: SES.event_type(report)
  defp event_name(_provider, event), do: event["event"]
end
