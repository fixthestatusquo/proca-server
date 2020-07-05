defmodule Proca.Contact.PopularInitiativeData do
  @moduledoc """
  Data gathered for Popular Initiative in Switzerland.
  """
  alias Proca.Contact.{Data, PopularInitiativeData}
  alias Proca.Contact
  import Ecto.Changeset

  @behaviour Data

  defstruct [
    first_name: nil,
    last_name: nil,
    birth_date: nil,
    email: nil,
    postcode: nil,
    locality: nil,
    region: nil
  ]
  @schema %{
    first_name: :string,
    last_name: :string,
    birth_date: :date,
    email: :string,
    postcode: :string,
    locality: :string,
    region: :string
  }

  @impl Data
  def from_input(params) do
    {%PopularInitiativeData{}, @schema}
    |> cast(params, [:first_name, :last_name, :birth_date, :email])
    |> cast(Map.get(params, :address, %{}), [:postcode, :locality, :region])
    |> validate_required([:first_name, :email, :postcode])
    |> Data.validate_email(:email)
    |> validate_format(:postcode, ~r/^\d{4}$/)
  end

  @impl Data
  def to_contact(%{valid?: true, changes: data}, _action_page) do
    data = if Map.has_key?(data, :birth_date) do
      %{data | birth_date: Date.to_string(data.birth_date)}
    else
      data
    end
    {Contact.build(data), fingerprint(data)}
  end

  defp fingerprint(data = %{first_name: fname, email: eml}) do
    seed = Application.get_env(:proca, Proca.Supporter)[:fpr_seed]
    x = fname <> Map.get(data, :last_name, "") <> eml <> Map.get(data, :birth_date, "")
    hash = :crypto.hash(:sha256, seed <> x)
    hash
  end

end
