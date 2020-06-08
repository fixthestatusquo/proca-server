defmodule ContactTest do
  use Proca.DataCase
  doctest Proca.Contact
  alias Proca.{Contact, PublicKey, Org, Repo}
  alias Proca.Server.Encrypt

  test "can be encrypted for 2 keys" do
    # some pauload and Contact changeset

    payload = %{ "test" => true }
    {:ok, payload_json} = JSON.encode(payload)
    
    c = Contact.build(payload)

    # Create recipient org with two keys
    o = create_org("test_org")
    {:ok, pk1} = PublicKey.build_for(o) |> Repo.insert
    {:ok, pk2} = PublicKey.build_for(o) |> Repo.insert

    # Encrypt the contact for both keys
    ce = Contact.encrypt(c, [pk1, pk2])
    assert Enum.count(ce) == 2
    Enum.all?(ce, fn %Ecto.Changeset{valid?: b} -> b end)

    crypted = Enum.map(ce, fn %{changes: %{payload: p, crypto_nonce: cn}} ->
      {p, cn}
    end)
    [{p1, cn1}, {p2, cn2}] = crypted

    assert Encrypt.decrypt(pk1, p1, cn1) == payload_json
    assert Encrypt.decrypt(pk2, p2, cn2) == payload_json
  end

  test "basic data creates contact changeset" do
    alias Proca.Contact.BasicData
    ap = Factory.insert(:action_page)
    chg = BasicData.from_input(%{
          name: "Hans Castorp",
          email: "hans@castorp.net"
                               })
    assert chg.valid?

    con_chg = BasicData.to_contact(chg, ap)
    {%{valid?: true, changes: cd}, fpr} = con_chg

    assert byte_size(fpr) > 0
  end
end
