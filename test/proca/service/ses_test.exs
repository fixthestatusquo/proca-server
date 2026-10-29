defmodule Proca.Service.SESTest do
  use ExUnit.Case, async: true

  alias Proca.Service.SES
  alias Swoosh.Email

  describe "custom id on outgoing email" do
    test "is sent as header and as SES tags" do
      email =
        Email.new()
        |> Email.put_private(:custom_id, "mtt:42")
        |> SES.put_custom_id()

      assert email.headers["X-Proca-Id"] == "mtt:42"

      assert email.provider_options.tags == [
               %{name: "proca_type", value: "mtt"},
               %{name: "proca_id", value: "42"}
             ]
    end

    test "matches what SES sends back in a real bounce report" do
      # recorded from SES (simulator bounce), account id and ips replaced
      %{"mail" => %{"tags" => reported_tags, "headers" => reported_headers}} =
        "test/fixtures/ses/bounce_event.json" |> File.read!() |> Jason.decode!()

      email =
        Email.new()
        |> Email.put_private(:custom_id, "action:123")
        |> SES.put_custom_id()

      for %{name: name, value: value} <- email.provider_options.tags do
        assert reported_tags[name] == [value]
      end

      for {name, value} <- email.headers do
        assert %{"name" => name, "value" => value} in reported_headers
      end
    end

    test "is not added for user emails (tag values cannot hold an address)" do
      email =
        Email.new()
        |> Email.put_private(:custom_id, "user:jo@example.org")
        |> SES.put_custom_id()

      assert email.headers == %{}
      assert email.provider_options == %{}
    end
  end

  describe "reports" do
    setup do
      # unique handler id, tests run async
      id = make_ref()
      test_pid = self()

      :telemetry.attach_many(
        id,
        [[:mailer, :ses, :bounces], [:mailer, :ses, :events]],
        fn event, _measurements, meta, _ -> send(test_pid, {event, meta.reason}) end,
        nil
      )

      on_exit(fn -> :telemetry.detach(id) end)

      %{report: "test/fixtures/ses/bounce_event.json" |> File.read!() |> Jason.decode!()}
    end

    test "bounces are counted by event type", %{report: report} do
      SES.handle_bounce(report)
      assert_received {[:mailer, :ses, :bounces], "Bounce"}
    end

    test "events are counted by event type", %{report: report} do
      SES.handle_event(%{report | "eventType" => "Delivery"})
      assert_received {[:mailer, :ses, :events], "Delivery"}
    end

    test "identity notifications use notificationType", %{report: report} do
      report = report |> Map.delete("eventType") |> Map.put("notificationType", "Delivery")
      SES.handle_event(report)
      assert_received {[:mailer, :ses, :events], "Delivery"}
    end

    test "malformed reports are not counted, only warned about", %{
      report: report
    } do
      log =
        ExUnit.CaptureLog.capture_log(fn ->
          SES.handle_event(Map.delete(report, "eventType"))
          SES.handle_bounce(Map.delete(report, "mail"))
        end)

      assert log =~ "Malformed SES report"
      refute_received {[:mailer, :ses, _], _}
    end
  end
end
