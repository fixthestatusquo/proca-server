defmodule ContactTest do
  use Proca.DataCase
  doctest Proca.Contact
  alias Proca.{Contact, PublicKey, Org, Repo, ActionPage, Supporter}
  alias Proca.Server.Encrypt
  alias Proca.Contact.Data
  
  test "build contact and supporter from basic data" do
    action_page = Factory.build(:action_page)

    data = Factory.build(:basic_data_pl)
    assert %Proca.Contact.BasicData{} = data

    # check creating contact from this
    contact_ch = %Ecto.Changeset{} = Data.to_contact(data, action_page)
    contact = apply_changes contact_ch
    assert %Contact{} = contact
    assert not is_nil contact.payload

    # Check payload
    decoded_data = Jason.decode! contact.payload
    assert decoded_data["firstName"] == data.first_name
    assert decoded_data["lastName"] == data.last_name
    assert is_nil contact.crypto_nonce
    assert not contact.communication_consent
    assert not contact.delivery_consent
    assert contact.communication_scopes == []

    # check supporter
    new_supporter = Supporter.new_supporter(data, action_page)
    assert new_supporter.valid?

    supporter = apply_changes new_supporter
    assert %Supporter{} = supporter
    assert supporter.first_name == data.first_name
    assert supporter.email == data.email
    assert not is_nil supporter.campaign
    assert not is_nil supporter.action_page
  end

  test "basic data without email fails" do
    action_page = Factory.build(:action_page)

    attrs = %{name: "Foo Bar", email: ""}
    data = ActionPage.new_data(attrs, action_page)
    assert not data.valid?
    assert not is_nil List.keyfind(data.errors, :email, 0)
  end

  test "basic data without address fields" do
    action_page = Factory.build(:action_page)
    attrs = %{name: "James Bond", email: "notshaken@gmail.com", postcode: "1234"}
    data = ActionPage.new_data(attrs, action_page)
    assert data.valid?
    
    contact = Data.to_contact(apply_changes(data), action_page)
    fields = Jason.decode!(get_change(contact, :payload))

    assert length(Map.keys(fields)) == 3
    assert fields["email"] == "notshaken@gmail.com"
    assert fields["firstName"] == "James"
    assert fields["lastName"] == "Bond"

  end

  test "BasicData.from_input and to_contact produce contact changeset and fingerprint" do
    alias Proca.Contact.BasicData
    ap = Factory.insert(:action_page)
    chg = BasicData.from_input(%{
          name: "Hans Castorp",
          email: "hans@castorp.net"
                               })
    assert chg.valid?
    data = apply_changes(chg)
    assert %BasicData{} = data

    %{valid?: true, changes: cd} =  Data.to_contact(data, ap)

    fpr = Data.fingerprint(data)
    assert byte_size(fpr) > 0
  end
end
