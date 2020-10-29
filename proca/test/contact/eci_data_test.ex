defmodule EciDataTest do
  use Proca.DataCase
  doctest Proca.Contact.EciData

  alias Proca.Contact.Data
  alias Proca.Contact.{Input, EciData}
  import Ecto.Changeset

  setup do
    names = %{
      first_name: "Alicia", last_name: "Witch"
    }

    address = %{
      street: "Exarcheia",
      street_number: "161",
      locality: "Athens",
      country: "Greece",
      postcode: "12345"
    }

    %{
      at_passport: %{
        nationality: %{
          country: "at", document_type: "passport", document_number: "R1234567"
        }
      } |> Map.merge(names),

      gr: %{
        nationality: %{
          country: "gr"
        },
        address: address
      } |> Map.merge(names)
    }
  end

  test "validate_older works" do
    # XXX this test will fail in 2030 because validator uses current date :O
    c = change(%EciData{}, birth_date: ~D[2000-02-13])
    |> Input.validate_older(:birth_date, 18)
    assert c.valid?

    c = change(%EciData{}, birth_date: ~D[2000-02-13])
    |> Input.validate_older(:birth_date, 30)
    assert not c.valid?
  end

  test "Austrian with passport", %{at_passport: d} do
    c = EciData.from_input(d)
    assert c.valid?

    n = d.nationality
    bad_passport_format = %{d |nationality: %{n | document_number: "AB12345"}}
    c = EciData.from_input(bad_passport_format)
    assert not c.valid?
    assert [{:document_number, {_, [validation: :format]}}] = c.errors
  end

  test "Austrian with problematic documents", %{at_passport: d} do
    n = d.nationality
    no_dn = %{d|nationality: %{n|document_number: nil}}

    c = EciData.from_input(no_dn)
    assert not c.valid?
    assert [{:document_number, {_, [validation: :required]}}] = c.errors

    no_dt = %{d|nationality: %{n|document_type: nil}}
    c = EciData.from_input(no_dt)
    assert not c.valid?
    assert [{:document_type, {_, [validation: :required]}}] = c.errors

    no_docs = %{d|nationality: %{country: n.country}}
    c = EciData.from_input(no_docs)
    assert not c.valid?
    assert [document_type: {_, [validation: :required]},
      document_number: {_, [validation: :required]}] = c.errors

    wrong_type = %{d|nationality: %{n|document_type: "id.card"}}
    c = EciData.from_input(wrong_type)
    assert not c.valid?
    assert [document_number: {_, [validation: :format]}] = c.errors

    unsupported_type = %{d |nationality: %{n|document_type: "pesel"}}
    c = EciData.from_input(unsupported_type)
    assert not c.valid?
    assert [{:document_type, {_, [{:validation, :inclusion} | _enum]}}] = c.errors
  end

  test "Greek with address", %{gr: d} do
    c = EciData.from_input(d)
    assert c.valid?
  end
end
