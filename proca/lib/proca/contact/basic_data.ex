defmodule Proca.Contact.BasicData do
  @moduledoc """
  Basic data represents the most typical data set we collect on membres: email
  as main identifier, names, postcode and country for locality, and optional
  phone number.
  """
  use Ecto.Schema

  alias Proca.Contact.{BasicData, Input}
  alias Proca.Contact
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :first_name, :string
    field :last_name, :string
    field :email, :string
    field :phone, :string
    field :country, :string
    field :postcode, :string
    field :area, :string
  end

  @behaviour Input
  @impl Input
  def from_input(params) do
    ch =
      params
      |> Input.Contact.normalize_names_attr()
      |> Input.Contact.changeset()
      |> validate_required([:name, :first_name, :email])

    if ch.valid? do
      d = apply_changes(ch)
      a = Map.get(d, :address) || %Input.Address{}

      change(%BasicData{}, %{
        name: d.name,
        first_name: d.first_name,
        last_name: d.last_name,
        email: d.email,
        phone: d.phone,
        country: a.country,
        postcode: a.postcode,
        area: a.country  # XXX we can have some logic here to use some other area type
      })
      |> validate_length(:area, max: 5)
    else
      ch
    end
  end
end

defimpl Proca.Contact.Data, for: Proca.Contact.BasicData do
  alias Proca.Contact.BasicData
  alias Proca.Contact

  def to_contact(data, _action_page) do
    # XXX here we should check action_page.split_names
    %{data | name: nil}
    |> Contact.build()
  end

  def fingerprint(%BasicData{email: email}) when byte_size(email) > 0 do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]
    hash = :crypto.hash(:sha256, seed <> email)
    hash
  end
end
