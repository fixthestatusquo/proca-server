defmodule ItCiDataTest do
  use Proca.DataCase
  doctest Proca.Contact.ItCiData

  alias Proca.Contact.ItCiData
  alias Proca.Contact.Data
  alias Proca.Contact.{Input}
  import Proca.Repo
  import Ecto.Changeset
  alias Proca.Factory
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

    page = Factory.insert(:action_page)
    org = change(page.org, contact_schema: :it_ci) |> update!
    page = %{page|org: org, campaign: %{page.campaign| org: org}}

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
      } |> Map.merge(names),

      page: page
    }
  end

  test "validates with passport", %{italian_passport: d, page: page} do 
    c = ItCiData.from_input(d)
    assert c.valid?

    {:ok, %{contact_ref: ref}} = ProcaWeb.Resolvers.Action.add_action_contact(nil, %{
      action_page_id: page.id,
      action: %{
        action_type: "register"
      },
      contact: d,
      privacy: %{
        opt_in: true, lead_opt_in: false
      }
    }, %{context: %{}, extensions: %{}})

    get_by(Proca.Supporter, fingerprint: ref) |> Proca.Repo.preload([:contacts]) |> IO.inspect(label: "stored")
  end

  test "validates with card", %{italian_card: d} do 
    c = ItCiData.from_input(d)
    assert c.valid?
  end

  test "validates with driving license", %{driving_license: d} do 
    c = ItCiData.from_input(d)
    assert c.valid?
  end

  test "validates with email added", %{italian_passport: d, page: page} do 
    Map.put(d, :email, "test@envelopi.it")
    c = ItCiData.from_input(d)
    assert c.valid?
  end
end
