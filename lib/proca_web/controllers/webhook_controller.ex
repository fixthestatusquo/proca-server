defmodule ProcaWeb.WebhookController do
  @moduledoc """
  Incoming webhook controller to process call backs from services like Mailjet, Brevo, SES, etc
  """
  use ProcaWeb, :controller

  alias Proca.Service.Mailjet
  alias Proca.Service.Brevo

  @doc """
  Mailjet sends an array of events. Phoenx Plug wraps this in _json key because params is a map and array would break merging other params
  """
  def mailjet(conn, %{"_json" => events}) do
    for %{"event" => et} = event <- events do
      cond do
        et in ["blocked", "spam", "unsub"] ->
          Mailjet.handle_bounce(event)

        # Ignore temporary soft bounces
        et == "bounce" and event["hard_bounce"] == true ->
          Mailjet.handle_bounce(event)

        true ->
          Mailjet.handle_event(event)
      end
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
    if et in @brevo_bounce_events do
      Brevo.handle_bounce(event)
    else
      Brevo.handle_event(event)
    end

    conn |> send_resp(:ok, "")
  end

  def brevo(conn, _params) do
    conn |> send_resp(:ok, "")
  end
end
