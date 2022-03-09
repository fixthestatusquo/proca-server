defmodule ProcaWeb.WebhookController do
  @moduledoc """
  Incoming webhook controller to process call backs from services like Mailjet and SES, etc
  """
  use ProcaWeb, :controller

  alias Proca.Service.Mailjet

  @doc """
  Mailjet sends an array of events. Phoenx Plug wraps this in _json key because params is a map and array would break merging other params
  """
  def mailjet(conn, %{"_json" => events}) do
    for %{"event" => et} = event <- events do
      if et in ["bounce", "blocked", "spam", "unsub"] do
        Mailjet.handle_bounce(event)
      else
        Mailjet.handle_event(event)
      end
    end

    conn
    |> send_resp(:ok, "")
  end
end
