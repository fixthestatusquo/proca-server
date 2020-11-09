defmodule Proca.Contact.PopularInitiativeData do
  @moduledoc """
  Data gathered for Popular Initiative in Switzerland.
  """
  use Ecto.Schema

  alias Proca.Contact.{Input, PopularInitiativeData}
  alias Proca.Contact
  import Ecto.Changeset

  embedded_schema do
    field :first_name, :string
    field :last_name, :string
    field :birth_date, :date
    field :email, :string
    field :postcode, :string
    field :locality, :string
    field :region, :string
    # field :address, :string # XXX not sent by widget - a bug ?
  end

  def validate_address(ch = %{valid?: false}), do: ch

  def validate_address(ch) do
    addr =
      get_change(ch, :address)
      |> validate_required(:postcode)
      |> validate_format(:postcode, ~r/^\d{4}$/)

    put_embed(ch, :address, addr)
  end

  @behaviour Input
  @impl Input
  def from_input(params) do
    ch =
      Input.Contact.changeset(params)
      |> validate_required([:first_name, :email, :address])
      |> Input.validate_email(:email)
      |> validate_address()

    if ch.valid? do
      d = apply_changes(ch)

      change(%PopularInitiativeData{}, %{
        first_name: d.first_name,
        last_name: d.last_name,
        birth_date: d.birth_date,
        email: d.email,
        postcode: d.address.postcode,
        locality: d.address.locality,
        region: d.address.region
      })
    else
      ch
    end
  end
end

defimpl Proca.Contact.Data, for: Proca.Contact.PopularInitiativeData do
  alias Proca.Contact

  def to_contact(data, _action_page) do
    data =
      if data.birth_date do
        %{data | birth_date: Date.to_string(data.birth_date)}
      else
        data
      end

    Contact.build(data)
  end

  def fingerprint(data = %Proca.Contact.PopularInitiativeData{first_name: fname, email: eml}) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]

    bdate =
      if data.birth_date do
        Date.to_string(data.birth_date)
      else
        ""
      end

    x = fname <> (data.last_name || "") <> eml <> bdate
    hash = :crypto.hash(:sha256, seed <> x)
    hash
  end
end
