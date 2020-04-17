defmodule Proca.Contact.BasicData do
  alias Proca.Contact.{Data, BasicData}
  alias Proca.Contact
  import Ecto.Changeset

  @behaviour Data

  defstruct [
    name: nil,
    first_name: nil,
    last_name: nil,
    email: nil,
    phone: nil,
    country: nil,
    postcode: nil]
  @schema %{
    name: :string,
    first_name: :string,
    last_name: :string,
    email: :string,
    phone: :string,
    country: :string,
    postcode: :string
  }


  @impl Data
  def from_input(params) do
    normalized = Data.normalize_names_attr(params)

    # name and contact
    chst = {%BasicData{}, @schema}
    |> cast(normalized, [:name, :first_name, :last_name, :email, :phone])

    # address
    chst2 = case Map.get(normalized, :address) do
              nil -> chst
              addr -> cast(chst, addr, [:country, :postcode])
    end

    validated = chst2
    |> validate_required([:name, :first_name, :email])
    |> Data.validate_email(:email)
    |> Data.validate_phone(:phone)

    validated
  end

  @impl Data
  def to_contact(chst = %{valid?: true}, _action_page) do
    # XXX here we should check action_page.split_names
    {:ok, payload} = chst.changes
    |> Map.delete(:name)
    |> JSON.encode()

    Contact.changeset(%Contact{},
      chst.changes
      |> Map.put(:payload, payload))
  end

end
