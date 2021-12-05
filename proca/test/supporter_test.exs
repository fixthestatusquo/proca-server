defmodule SupporterTest do
  use Proca.DataCase
  doctest Proca.Supporter
  alias Proca.{Contact, PublicKey, Org, Repo, ActionPage, Supporter, Action}
  alias Proca.Supporter.Privacy
  alias Proca.Server.Encrypt
  alias Proca.Factory

  import Ecto.Changeset
  import Proca.StoryFactory, only: [blue_story: 0]

  test "distributing personal data for blue org" do
    %{
      org: org,
      pages: [ap]
    } = blue_story()

    contact = Factory.params_for(:basic_data_pl_contact, action_page: ap)
    supporter = Factory.params_for(:basic_data_pl_supporter, action_page: ap)

    new_contact = change(%Contact{}, contact)
    new_supporter = change(%Supporter{}, supporter)

    create_sup =
      Supporter.add_contacts(
        new_supporter,
        new_contact,
        ap,
        %Privacy{opt_in: true}
      )

    assert {:ok, sup_of_blue_org} = Repo.insert(create_sup)

    assert length(sup_of_blue_org.contacts) == 1
    assert is_nil(hd(sup_of_blue_org.contacts).crypto_nonce)
    assert not is_nil(hd(sup_of_blue_org.contacts).payload)
  end

  test "handle_bounce adds bounce reason" do
    action = Factory.insert(:action)
    supporter = action.supporter

    params = %{
      id: action.id,
      email: supporter.email,
      reason: :spam
    }

    Supporter.handle_bounce(params)

    supporter = Supporter.get_by_action_id(action.id)

    assert supporter.email_status == :spam
  end

  test "handle_bounce marks status as rejected" do
    action = Factory.insert(:action)
    supporter = action.supporter

    Repo.update(change(action, processing_status: :confirming))
    Repo.update(change(action.supporter, processing_status: :confirming))

    params = %{
      id: action.id,
      email: supporter.email,
      reason: :spam
    }

    Supporter.handle_bounce(params)

    supporter = Supporter.get_by_action_id(action.id)

    assert supporter.processing_status == :rejected
  end
end
