defmodule Proca.Address do
  import Ecto.Changeset
  alias Proca.Address

  defstruct country: nil, postcode: nil
  @address_schema %{country: :string, postcode: :string}

  def from_input(nil) do
    nil
  end

  def from_input(address, _action_page) do
    {%Address{}, @address_schema}
    |> cast(address, Map.keys(@address_schema))
  end
end
