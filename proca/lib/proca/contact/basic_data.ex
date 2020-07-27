defmodule Proca.Contact.BasicData do
  @moduledoc """
  Basic data represents the most typical data set we collect on membres: email
  as main identifier, names, postcode and country for locality, and optional
  phone number.
  """

  alias Proca.Contact.{Data, BasicData, Input}
  alias Proca.Contact
  import Ecto.Changeset

  @derive Jason.Encoder
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

  @behaviour Input
  @impl Input
  def from_input(params) do
    normalized = Input.normalize_names_attr(params)

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
    |> Input.validate_email(:email)
    |> Input.validate_phone(:phone)

    validated
  end

end


defimpl Proca.Contact.Data, for: Proca.Contact.BasicData do
  alias Proca.Contact.{Data, BasicData, Input}
  alias Proca.Contact

  def to_contact(data, _action_page) do
    # XXX here we should check action_page.split_names
    data2 = Map.from_struct(data) |> Map.delete(:name)

    Contact.build(data2)
  end

  def fingerprint(%BasicData{email: email}) when byte_size(email) > 0 do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]
    hash = :crypto.hash(:sha256, seed <> email)
    hash
  end
end
