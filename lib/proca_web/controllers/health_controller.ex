defmodule ProcaWeb.HealthController do
  use ProcaWeb, :controller

  def index(conn, _params) do
    # Verify the database is reachable as a basic readiness check
    result =
      case Ecto.Adapters.SQL.query(Proca.Repo, "SELECT 1", []) do
        {:ok, _} -> :ok
        _ -> :error
      end

    case result do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, ~s({"status":"ok"}))

      :error ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(503, ~s({"status":"error","message":"database unreachable"}))
    end
  end
end
