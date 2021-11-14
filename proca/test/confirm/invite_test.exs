defmodule Proca.Confirm.InviteTest do 
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Factory

  alias Proca.{Confirm, Repo, Org}
  alias Proca.TestEmailBackend
  import Ecto.Changeset

  setup do 
    io = Org.instance_org_name()
    |> Org.get_by_name([:template_backend, :email_backend])

    io = io
    |> Org.put_service(Factory.insert(:email_backend, org: io))
    |> Repo.update!

    red_story()
    |> Map.put(:instance, io)
    |> Map.put(:email_backend, TestEmailBackend.start_link([]))
    |> Map.put(:notify_server, Proca.Server.Notify.start_link(Org.instance_org_name))
  end

  test "Invite red org to yellow campaign", %{red_bot: red_staff, yellow_ap: ap, yellow_org: yellow_org} do 
    cnf = Confirm.AddPartner.create(ap, red_staff.user.email)
    assert %{operation: :add_partner} = cnf
    assert String.length(cnf.code) > 0
    assert cnf.email == red_staff.user.email
    assert cnf.subject_id == ap.id

    assert :ok == Confirm.notify_by_email(cnf)
    
    [sent_mail] = TestEmailBackend.mailbox(red_staff.user.email)
    fields = sent_mail.private.fields[red_staff.user.email]
    assert fields["code"] == cnf.code


  end

end
