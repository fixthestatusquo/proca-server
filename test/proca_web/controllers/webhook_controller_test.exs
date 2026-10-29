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

  describe "ses" do
    @topic "arn:aws:sns:eu-west-3:123456789012:proca-ses-events"
    @cert_url "https://sns.eu-west-3.amazonaws.com/SimpleNotificationService-test.pem"
    @subscribe_url "https://sns.eu-west-3.amazonaws.com/?Action=ConfirmSubscription&Token=t"

    setup do
      %{pem: pem, key: key} = Proca.SNSSigner.generate_cert()
      :persistent_term.erase({Proca.Service.SNS, @cert_url})

      adapter = Application.get_env(:tesla, :adapter)
      config = Application.get_env(:proca, Proca.Service.SNS)
      Application.put_env(:tesla, :adapter, Tesla.Mock)
      Application.put_env(:proca, Proca.Service.SNS, topic_arns: [@topic])

      on_exit(fn ->
        Application.put_env(:tesla, :adapter, adapter)
        Application.put_env(:proca, Proca.Service.SNS, config)
        :persistent_term.erase({Proca.Service.SNS, @cert_url})
      end)

      test_pid = self()

      Tesla.Mock.mock(fn
        %{method: :get, url: @cert_url} ->
          %Tesla.Env{status: 200, body: pem}

        %{method: :get, url: @subscribe_url} ->
          send(test_pid, :subscribed)
          %Tesla.Env{status: 200, body: ""}
      end)

      %{key: key}
    end

    # SNS posts JSON as text/plain
    defp post_sns(conn, msg) do
      conn
      |> put_req_header("content-type", "text/plain; charset=UTF-8")
      |> post("/webhook/ses", Jason.encode!(msg))
    end

    defp sns_message(type, fields) do
      Map.merge(
        %{
          "Type" => type,
          "MessageId" => "c1c802ef-9d1e-5d7b-bd29-61b47528230a",
          "TopicArn" => @topic,
          "Timestamp" => "2026-10-28T12:09:26.298Z",
          "SignatureVersion" => "1",
          "SigningCertURL" => @cert_url
        },
        fields
      )
    end

    defp bounce_notification() do
      sns_message("Notification", %{
        "Subject" => "Amazon SES Email Event Notification",
        "Message" => File.read!("test/fixtures/ses/bounce_event.json")
      })
    end

    test "accepts a signed report", %{conn: conn, key: key} do
      conn = post_sns(conn, bounce_notification() |> Proca.SNSSigner.sign(key))
      assert response(conn, 200) == ""
    end

    test "accepts the topic validation message, which is not JSON", %{conn: conn, key: key} do
      msg =
        sns_message("Notification", %{
          "Message" => "Successfully validated SNS topic for Amazon SES event publishing."
        })

      conn = post_sns(conn, msg |> Proca.SNSSigner.sign(key))
      assert response(conn, 200) == ""
    end

    test "confirms the subscription", %{conn: conn, key: key} do
      msg =
        sns_message("SubscriptionConfirmation", %{
          "Message" => "You have chosen to subscribe to the topic",
          "SubscribeURL" => @subscribe_url,
          "Token" => "t"
        })

      conn = post_sns(conn, msg |> Proca.SNSSigner.sign(key))
      assert response(conn, 200) == ""
      assert_received :subscribed
    end

    test "refuses a changed report", %{conn: conn, key: key} do
      msg =
        bounce_notification()
        |> Proca.SNSSigner.sign(key)
        |> Map.update!("Message", &String.replace(&1, "action", "mtt"))

      capture_log(fn ->
        conn = post_sns(conn, msg)
        assert response(conn, 403) == ""
      end)
    end

    test "logs an error for a signed message from a topic not in the allowlist", %{
      conn: conn,
      key: key
    } do
      Application.put_env(:proca, Proca.Service.SNS, topic_arns: [])

      log =
        capture_log(fn ->
          conn = post_sns(conn, bounce_notification() |> Proca.SNSSigner.sign(key))
          assert response(conn, 403) == ""
        end)

      assert log =~ "[error]"
      assert log =~ "add it to SES_SNS_TOPIC_ARNS"
    end

    test "does not confirm an unsigned subscription", %{conn: conn} do
      msg =
        sns_message("SubscriptionConfirmation", %{
          "Message" => "You have chosen to subscribe to the topic",
          "SubscribeURL" => @subscribe_url,
          "Token" => "t",
          "Signature" => "bm90IHNpZ25lZA=="
        })

      capture_log(fn ->
        conn = post_sns(conn, msg)
        assert response(conn, 403) == ""
      end)

      refute_received :subscribed
    end

    test "refuses a body that is not JSON", %{conn: conn} do
      capture_log(fn ->
        conn =
          conn
          |> put_req_header("content-type", "text/plain")
          |> post("/webhook/ses", "hello")

        assert response(conn, 403) == ""
      end)
    end
  end
end
