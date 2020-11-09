defmodule SupporterTest do
  use Proca.DataCase
  doctest Proca.Supporter
  alias Proca.{Contact, PublicKey, Org, Repo, ActionPage, Supporter}
  alias Proca.Supporter.Privacy
  alias Proca.Server.Encrypt
  alias Proca.Factory

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
end
