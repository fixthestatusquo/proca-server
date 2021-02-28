defmodule EciDataTest do
  use Proca.DataCase
  doctest Proca.Contact.EciData

  alias Proca.Contact.Data
  alias Proca.Contact.{Input, EciData}
  import Ecto.Changeset
  import ProcaWeb.Helper, only: [format_errors: 1]

  setup do
    names = %{
      first_name: "Alicia",
      last_name: "Witch Switch"
    }

    address = %{
      street: "Exarcheia",
      street_number: "161",
      locality: "Athens",
      country: "GR",
      postcode: "12345"
    }

    %{
      at_passport:
        %{
          nationality: %{
            country: "AT",
            document_type: "passport",
            document_number: "R1234567"
          }
        }
        |> Map.merge(names),
      gr:
        %{
          nationality: %{
            country: "GR"
          },
          address: address
        }
        |> Map.merge(names),
      fr_in_be:
        %{
          birth_date: ~D[1900-01-02],
          nationality: %{
            country: "FR"
          },
          address: %{
            country: "BE",
            postcode: "1234",
            locality: "Brussels",
            street: "l'Amour Fries 11"
          }
        }
        |> Map.merge(names)
    }
  end

  test "validate_older works" do
    # XXX this test will fail in 2030 because validator uses current date :O
    c =
      change(%EciData{}, birth_date: ~D[2000-02-13])
      |> Input.validate_older(:birth_date, 18)

    assert c.valid?

    c =
      change(%EciData{}, birth_date: ~D[2000-02-13])
      |> Input.validate_older(:birth_date, 30)

    assert not c.valid?
  end

  test "Austrian with passport", %{at_passport: d} do
    c = EciData.from_input(d)
    assert c.valid?

    n = d.nationality
    bad_passport_format = %{d | nationality: %{n | document_number: "AB12345"}}
    c = EciData.from_input(bad_passport_format)
    assert not c.valid?

    assert [
             %{
               message: "documentNumber: has invalid format",
               path: ["nationality", "documentNumber"]
             }
           ] = format_errors(c)
  end

  test "Austrian with problematic documents", %{at_passport: d} do
    n = d.nationality
    no_dn = %{d | nationality: %{n | document_number: nil}}

    c = EciData.from_input(no_dn)

    assert not c.valid?
    assert [%{message: "documentNumber: can't be blank", path: ["nationality", "documentNumber"]}] =
             format_errors(c)

    no_dt = %{d | nationality: %{n | document_type: nil}}
    c = EciData.from_input(no_dt)
    assert not c.valid?

    assert [%{message: "documentType: can't be blank", path: ["nationality", "documentType"]}] =
             format_errors(c)

    no_docs = %{d | nationality: %{country: n.country}}
    c = EciData.from_input(no_docs)
    assert not c.valid?

    assert [
             %{
               message: "documentNumber: can't be blank",
               path: ["nationality", "documentNumber"]
             },
             %{message: "documentType: can't be blank", path: ["nationality", "documentType"]}
           ] = format_errors(c)

    wrong_type = %{d | nationality: %{n | document_type: "id.card"}}
    c = EciData.from_input(wrong_type)
    assert not c.valid?

    assert [
             %{
               message: "documentNumber: has invalid format",
               path: ["nationality", "documentNumber"]
             }
           ] = format_errors(c)

    unsupported_type = %{d | nationality: %{n | document_type: "pesel"}}
    c = EciData.from_input(unsupported_type)
    assert not c.valid?

    assert [%{message: "documentType: is invalid", path: ["nationality", "documentType"]}] =
             format_errors(c)

    dn_spaces = %{d | nationality: %{n | document_number: "R 1234567" } }

    assert not c.valid?

    c = EciData.from_input(no_dn)

    assert not c.valid?
  end

  test "Greek with address", %{gr: d} do
    c = EciData.from_input(d)
    assert c.valid?
    assert get_change(c, :city) == "Athens"
  end

  test "Greek with missing address country", %{gr: gr} do
    d = %{gr | address: %{gr.address | country: nil}}
    c = EciData.from_input(d)
    assert not c.valid?
    assert [%{message: "country: can't be blank", path: ["address", "country"]}] = format_errors(c)
  end

  test "Greek with missing locality", %{gr: gr} do
    d = %{gr | address: %{gr.address | locality: nil}}
    c = EciData.from_input(d)
    assert not c.valid?

    assert [%{message: "locality: can't be blank", path: ["address", "locality"]}] =
             format_errors(c)
  end

  test "Greek with ill formatted postcode", %{gr: gr} do
    d = %{gr | address: %{gr.address | postcode: "123"}}
    c = EciData.from_input(d)
    assert not c.valid?

    assert [%{message: "postcode: has invalid format", path: ["address", "postcode"]}] =
             format_errors(c)
  end

  test "Greek with spaces/hyphens in postcode", %{gr: gr} do
    d = %{gr | address: %{gr.address | postcode: "123-45"}}
    c = EciData.from_input(d)
    assert c.valid?

    d = %{gr | address: %{gr.address | postcode: "123 45"}}
    c = EciData.from_input(d)
    assert c.valid?
  end

  test "Greek with dot in last name", %{gr: gr} do 
    d = %{gr | last_name: "Mr. Something"}
    c = EciData.from_input(d)
    assert c.valid?
  end 

  test "Greek with lowercase country name is upcased", %{gr: gr} do
    d = %{gr | nationality: %{gr.nationality | country: "gr"}}
    c = EciData.from_input(d)
    assert c.valid?

    record = apply_changes(c)
    assert record.nationality.country == "GR"
  end

  test "French living in Belgium passes with 4-digit postcode", %{fr_in_be: fr_in_be} do
    c = EciData.from_input(fr_in_be)
    assert c.valid?
    record = apply_changes(c)
    assert record.nationality.country == "FR"
    assert record.country == "BE"
  end
end
