defmodule ContactDataTest do
  use Proca.DataCase
  import Ecto.Changeset
  alias Proca.Contact.BasicData

  test "Create a BasicData from params" do
    params = %{
      first_name: "Harald",
      last_name: "Bower",
      email: "harhar@gmail.com",
      address: %{
        country: "it",
        postcode: "0993"
      }
    }

    new_data = BasicData.from_input(params)
    data = apply_changes(new_data)

    assert %BasicData{first_name: "Harald", last_name: "Bower", email: "harhar@gmail.com"} = data
  end

  test "Phone must have a good format" do
    params = %{
      first_name: "Caller",
      email: "caller@somewhere.org"
    }

    new_data = BasicData.from_input(params |> Map.put(:phone, "Street 123"))
    assert %{errors: [phone: {"has invalid format", [validation: :format]}]} = new_data

    new_data = BasicData.from_input(params |> Map.put(:phone, "+48123456789"))
    data = apply_changes(new_data)
    assert data = %{phone: "+48123456789"}
  end
end
