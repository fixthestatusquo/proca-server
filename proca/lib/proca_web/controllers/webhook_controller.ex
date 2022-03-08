defmodule ProcaWeb.WebhookController do
  @moduledoc """
  Incoming webhook controller to process call backs from services like Mailjet and SES, etc
  """
  use ProcaWeb, :controller

  alias Proca.Service.Mailjet

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
