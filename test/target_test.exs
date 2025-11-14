defmodule TargetTest do
  use Proca.DataCase
  doctest Proca.Supporter
  alias Proca.{Target, TargetEmail}
  alias Proca.Factory

  setup do
    target = Factory.insert(:target)
    message = Factory.insert(:message, %{target: target})
    email = Enum.at(target.emails, 0)

    %{
      target: target,
      message: message,
      email: email
    }
  end

  test "handle_bounce adds bounce reason", %{target: target, message: message, email: email} do
    params = %{
      id: message.id,
      email: email.email,
      reason: :blocked
    }

    Target.handle_bounce(params)

    email = Repo.get_by!(TargetEmail, email: email.email)

    assert email.email_status == :blocked
  end

  @bounce_event1 """
  {
  "event": "bounce",
  "time": 1430812195,
  "MessageID": 13792286917004336,
  "Message_GUID": "1ab23cd4-e567-8901-2345-6789f0gh1i2j",
  "email": "bounce@mailjet.com",
  "mj_campaign_id": 0,
  "mj_contact_id": 0,
  "customcampaign": "",
  "CustomID": "helloworld",
  "Payload": "",
  "blocked": false,
  "hard_bounce": true,
  "error_related_to": "recipient",
  "error": "user unknown",
  "comment": "Host or domain name not found. Name service error for name=lbjsnrftlsiuvbsren.com type=A: Host not found"
  }
  """

  test "bounce event from Mailjet", %{target: target, message: message, email: email} do
    event =
      @bounce_event1
      |> Jason.decode!()
      |> Map.put("email", email.email)
      |> Map.put("CustomID", "mtt:#{message.id}")

    target_email = Proca.Service.Mailjet.handle_bounce(event)

    assert target_email.error ==
             "recipient: user unknown: Host or domain name not found. Name service error for name=lbjsnrftlsiuvbsren.com type=A: Host not found"
  end

  test "Delete a target", %{target: t} do
    import Ecto.Changeset
    alias Proca.Repo

    del_res =
      t
      |> Target.deleteset()
      |> Repo.delete()
      |> IO.inspect()

    assert del_res =
             {:error,
              %{
                errors: [
                  messages:
                    {"has messages",
                     [constraint: :foreign, constraint_name: "messages_target_id_fkey"]}
                ]
              }}
  end
end
