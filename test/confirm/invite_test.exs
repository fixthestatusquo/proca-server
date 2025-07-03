defmodule Proca.Confirm.InviteTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Factory

  alias Proca.{Confirm, Repo, Org}
  use Proca.TestEmailBackend
  import Ecto.Changeset

  setup do
    red_story()
  end

  test "Invite red org to yellow campaign", %{
    red_bot: red_staff,
    yellow_ap: ap,
    yellow_org: yellow_org
  } do
    cnf =
      Confirm.AddPartner.changeset(ap, red_staff.user.email)
      |> Confirm.insert_and_notify!()

    assert %{operation: :add_partner} = cnf
    assert String.length(cnf.code) > 0
    assert cnf.email == red_staff.user.email
    assert cnf.subject_id == ap.id

    [sent_mail] = TestEmailBackend.mailbox(red_staff.user.email)
    fields = sent_mail.assigns
    assert fields["code"] == cnf.code
  end
end
