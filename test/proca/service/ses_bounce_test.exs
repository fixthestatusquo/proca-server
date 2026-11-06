defmodule Proca.Service.SESBounceTest do
  use Proca.DataCase

  import ExUnit.CaptureLog
  alias Proca.{Factory, Supporter, TargetEmail}
  alias Proca.Service.SES

  setup do
    target = Factory.insert(:target)
    message = Factory.insert(:message, %{target: target})

    %{
      message: message,
      email: Enum.at(target.emails, 0).email,
      # recorded from SES (simulator bounce), see ses_test.exs
      report: "test/fixtures/ses/bounce_event.json" |> File.read!() |> Jason.decode!()
    }
  end

  # the fixture report, for our id and recipient
  defp bounce(report, type, id, email, bounce_type \\ "Permanent") do
    report
    |> put_in(["mail", "tags", "proca_type"], [type])
    |> put_in(["mail", "tags", "proca_id"], ["#{id}"])
    |> put_in(["mail", "destination"], [email])
    |> put_in(["bounce", "bounceType"], bounce_type)
    |> put_in(["bounce", "bouncedRecipients"], [
      %{"emailAddress" => email, "diagnosticCode" => "smtp; 550 5.1.1 user unknown"}
    ])
  end

  defp target_email(message, email), do: TargetEmail.one(message_id: message.id, email: email)

  describe "mtt" do
    test "a permanent bounce disables the target email", %{report: r, message: m, email: e} do
      SES.handle_bounce(bounce(r, "mtt", m.id, e))

      te = target_email(m, e)
      assert te.email_status == :bounce
      assert te.error == "smtp; 550 5.1.1 user unknown"
    end

    test "a transient bounce is a soft bounce", %{report: r, message: m, email: e} do
      capture_log(fn -> SES.handle_bounce(bounce(r, "mtt", m.id, e, "Transient")) end)

      assert target_email(m, e).soft_bounce_count == 1
    end

    test "a complaint marks it as spam", %{report: r, message: m, email: e} do
      report =
        r
        |> bounce("mtt", m.id, e)
        |> Map.delete("bounce")
        |> Map.merge(%{
          "eventType" => "Complaint",
          "complaint" => %{
            "complaintFeedbackType" => "abuse",
            "complainedRecipients" => [%{"emailAddress" => e}]
          }
        })

      SES.handle_bounce(report)

      te = target_email(m, e)
      assert te.email_status == :spam
      assert te.error == "abuse"
    end

    test "a reject blocks all recipients", %{report: r, message: m, email: e} do
      report =
        r
        |> bounce("mtt", m.id, e)
        |> Map.delete("bounce")
        |> Map.merge(%{"eventType" => "Reject", "reject" => %{"reason" => "Bad content"}})

      SES.handle_bounce(report)

      te = target_email(m, e)
      assert te.email_status == :blocked
      assert te.error == "Bad content"
    end

    test "our id is read from the header when there are no tags", %{
      report: r,
      message: m,
      email: e
    } do
      report =
        r
        |> bounce("mtt", m.id, e)
        |> update_in(["mail", "tags"], &Map.drop(&1, ["proca_type", "proca_id"]))
        |> put_in(["mail", "headers"], [%{"name" => "X-Proca-Id", "value" => "mtt:#{m.id}"}])

      SES.handle_bounce(report)

      assert target_email(m, e).email_status == :bounce
    end
  end

  describe "action" do
    setup do
      %{action: Factory.insert(:action)}
    end

    test "a permanent bounce rejects the supporter", %{report: r, action: a} do
      SES.handle_bounce(bounce(r, "action", a.id, a.supporter.email))

      assert Supporter.get_by_action_id(a.id).email_status == :bounce
    end

    test "a transient bounce changes nothing", %{report: r, action: a} do
      capture_log(fn ->
        SES.handle_bounce(bounce(r, "action", a.id, a.supporter.email, "Transient"))
      end)

      assert Supporter.get_by_action_id(a.id).email_status == :none
    end
  end

  test "a report without our id is ignored", %{report: r, message: m, email: e} do
    report =
      r
      |> bounce("mtt", m.id, e)
      |> update_in(["mail", "tags"], &Map.drop(&1, ["proca_type", "proca_id"]))
      |> put_in(["mail", "headers"], [])

    assert :ok = SES.handle_bounce(report)
    assert target_email(m, e).email_status == :none
  end
end
