defmodule ProcaWeb.WebhookControllerTest do
  use ProcaWeb.ConnCase

  import ExUnit.CaptureLog

  alias Proca.{Factory, Supporter}

  defp post_json(conn, path, body) do
    conn
    |> put_req_header("content-type", "application/json")
    |> post(path, Jason.encode!(body))
  end

  test "mailjet: a crashing event does not fail the rest of the batch", %{conn: conn} do
    action = Factory.insert(:action)

    events = [
      # space after the colon makes parse_custom_id raise
      %{"event" => "bounce", "email" => "x@example.com", "CustomID" => "action: 1"},
      %{
        "event" => "bounce",
        "email" => action.supporter.email,
        "CustomID" => "action:#{action.id}",
        "hard_bounce" => true
      }
    ]

    log =
      capture_log(fn ->
        conn = post_json(conn, "/webhook/mailjet", events)
        assert response(conn, 200) == ""
      end)

    assert log =~ "mailjet webhook event failed"
    assert log =~ ~s(custom_id: "action: 1")
    refute log =~ "x@example.com"

    assert Supporter.get_by_action_id(action.id).email_status == :bounce
  end

  test "brevo: a crashing event still returns 200", %{conn: conn} do
    capture_log(fn ->
      conn =
        post_json(conn, "/webhook/brevo", %{
          "event" => "delivered",
          "email" => "x@example.com",
          "tags" => ["action:not-a-number"]
        })

      assert response(conn, 200) == ""
    end)
  end
end
