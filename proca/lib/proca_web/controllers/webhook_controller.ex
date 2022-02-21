defmodule ProcaWeb.WebhookController do
  @moduledoc """
  Incoming webhook controller to process call backs from services like Mailjet and SES, etc
  """
  use ProcaWeb, :controller

  alias Proca.Service.Mailjet

  def mailjet(conn, params) do
    if Map.get(params, "event") in ["bounce", "blocked", "spam", "unsub"] do
      Mailjet.handle_bounce(params)
    else
      Mailjet.handle_event(params)
    end

    conn
    |> send_resp(:ok, "")
  end
end
