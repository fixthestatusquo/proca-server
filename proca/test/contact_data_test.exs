defmodule ContactDataTest do
  use Proca.DataCase
  import Ecto.Changeset
  alias Proca.Contact.BasicData

  test "Create a BasicData from params" do
    params = %{
      first_name: "Harald", last_name: "Bower",
      email: "harhar@gmail.com",
      address: %{
        country: "it", postcode: "0993"
      }
    }

    new_data = BasicData.from_input(params)
    data = apply_changes new_data

    assert %BasicData{first_name: "Harald", last_name: "Bower", email: "harhar@gmail.com"} = data
  end
end
