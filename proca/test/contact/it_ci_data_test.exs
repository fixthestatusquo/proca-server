defmodule ItCiDataTest do
  use Proca.DataCase
  doctest Proca.Contact.ItCiData

  alias Proca.Contact.ItCiData
  alias Proca.Contact.Data
  alias Proca.Contact.{Input}
  import Ecto.Changeset
  import ProcaWeb.Helper, only: [format_errors: 1]

  setup do
    names = %{
      first_name: "Antonio",
      last_name: "Negri",
      birth_date: ~D[1999-04-10]
    }

    address = %{
      street: "Romana",
      street_number: "161",
      locality: "Padua",
      country: "IT",
      postcode: "35121"
    }

    passport = %{
      country: "IT",
      document_type: "passport",
      document_number: "AA5275702"
    }

    id_card = %{
      country: "IT",
      document_type: "id.card",
      document_number: "CA00000AA"
    }

    drv_lic = %{
      country: "IT",
      document_type: "driving.license",
      document_number: "AB1234567X"
    }
    # return
    %{
      italian_passport: %{
        address: address, nationality: passport
      } |> Map.merge(names),

      italian_card: %{
        address: address, nationality: id_card
      } |> Map.merge(names),

      driving_license: %{
        address: address, nationality: drv_lic
      } |> Map.merge(names)
    }
  end

  test "validates with passport", %{italian_passport: d} do 
    c = ItCiData.from_input(d)
    assert c.valid?
  end

  test "validates with card", %{italian_card: d} do 
    c = ItCiData.from_input(d)
    assert c.valid?
  end

  test "validates with driving license", %{driving_license: d} do 
    c = ItCiData.from_input(d)
    assert c.valid?
  end
end
