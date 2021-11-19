defmodule TargetTest do
  use Proca.DataCase
  doctest Proca.Supporter
  alias Proca.{Target, TargetEmail}
  alias Proca.Factory

  test "handle_bounce adds bounce reason" do
    target = Factory.insert(:target)
    email = Enum.at(target.emails, 0)

    params = %{
      id: target.id,
      email: email.email,
      reason: :blocked
    }

    Target.handle_bounce(params)

    email = Repo.get_by!(TargetEmail, email: email.email)

    assert email.email_status == :blocked
  end
end
