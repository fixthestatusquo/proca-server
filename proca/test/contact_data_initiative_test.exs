defmodule ContactDataInitiativeTest do
  use Proca.DataCase
  import Ecto.Changeset
  alias Proca.Contact.{Data, PopularInitiativeData}

  test "Validates required fields" do
    params = %{
      first_name: "Georg",
      email: "katze@hund",
      address: %{
        postcode: "1234",
        locality: "Vessy",
        region: "GE",
        country: "CH"
      }
    }

    assert d = %{valid?: true} = PopularInitiativeData.from_input(params)
    f = Data.fingerprint(apply_changes(d))
    assert byte_size(f) > 0

    assert d =
             %{valid?: true} =
             PopularInitiativeData.from_input(Map.put(params, :last_name, "Berg"))

    f = Data.fingerprint(apply_changes(d))
    assert byte_size(f) > 0

    assert d =
             %{valid?: true} =
             PopularInitiativeData.from_input(Map.put(params, :birth_date, "1983-01-01"))

    f = Data.fingerprint(apply_changes(d))
    assert byte_size(f) > 0

    assert d = %{valid?: false} = PopularInitiativeData.from_input(params |> Map.delete(:email))
    assert List.keyfind(d.errors, :email, 0)
  end
end
