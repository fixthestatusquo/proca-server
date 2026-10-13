defmodule ProcaWeb.WebhookController do
  @moduledoc """
  Incoming webhook controller to process call backs from services like Mailjet, Brevo, SES, etc
  """
  use ProcaWeb, :controller

  require Logger

  alias Proca.Service.Mailjet
  alias Proca.Service.Brevo

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

  # A failing event must never turn into a 500: providers retry the whole batch
  # and, after repeated errors, mark our callback URL dead and stop calling
  # (this silently disabled Mailjet bounces for a year). Report and move on.
  defp safely(provider, event, fun) do
    fun.()
  rescue
    e ->
      extra = %{provider: provider, event: event["event"], custom_id: custom_id(provider, event)}

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
end
