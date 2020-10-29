defmodule Proca.Contact.PopularInitiativeData do
  @moduledoc """
  Data gathered for Popular Initiative in Switzerland.
  """
  use Ecto.Schema

  alias Proca.Contact.{Data, Input, PopularInitiativeData}
  alias Proca.Contact
  import Ecto.Changeset

  @derive Jason.Encoder
  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :birth_date, :date
    field :email, :string
    field :postcode, :string
    field :locality, :string
    field :region, :string
  end

  @behaviour Input
  @impl Input
  def from_input(params) do
    %PopularInitiativeData{}
    |> cast(params, [:first_name, :last_name, :birth_date, :email])
    |> cast(Map.get(params, :address, %{}), [:postcode, :locality, :region])
    |> validate_required([:first_name, :email, :postcode])
    |> Input.validate_email(:email)
    |> validate_format(:postcode, ~r/^\d{4}$/)
  end
end

defimpl Proca.Contact.Data, for: Proca.Contact.PopularInitiativeData do
  alias Proca.Contact.{Data, BasicData}
  alias Proca.Contact

  def to_contact(data, _action_page) do
    attrs = Map.from_struct(data)
    attrs = if data.birth_date do
      %{attrs | birth_date: Date.to_string(data.birth_date)}
    else
      attrs
    end
    Contact.build(attrs)
  end

  def fingerprint(data = %Proca.Contact.PopularInitiativeData{first_name: fname, email: eml}) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]

    bdate = if data.birth_date do
      Date.to_string(data.birth_date)
    else
      ""
    end

    x = fname <> (data.last_name || "") <> eml <> bdate
    hash = :crypto.hash(:sha256, seed <> x)
    hash
  end

end
