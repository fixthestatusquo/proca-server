defmodule Proca.Contact.Input.Contact do
  @moduledoc """
  Schema for handling contact: map from graphql addAction* mutations
  """
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :name, :string
    field :first_name, :string
    field :last_name, :string

    field :email, :string
    field :phone, :string

    field :birth_date, :date

    embeds_one :address, Proca.Contact.Input.Address
    embeds_one :nationality, Proca.Contact.Input.Nationality
  end

  def changeset(ch, params) do
    ch
    |> cast(params, [:name, :first_name, :last_name, :email, :phone, :birth_date])
    |> cast_embed(:address)
    |> cast_embed(:nationality)
  end

  def changeset(params) do
    changeset(%Proca.Contact.Input.Contact{}, params)
  end

  @doc "Given params with name or split name, recompute others"
  def normalize_names_attr(attr = %{first_name: _, name: _}) do
    attr
  end

  def normalize_names_attr(attr = %{first_name: fst, last_name: lst}) do
    attr
    |> Map.put(:name, String.trim("#{fst} #{lst}"))
  end

  def normalize_names_attr(attr = %{first_name: fst}) do
    attr
    |> Map.put(:name, String.trim(fst))
  end

  def normalize_names_attr(attr = %{name: n}) do
    [first | rest] = String.split(n, " ")

    attr
    |> Map.put(:first_name, first)
    |> Map.put(:last_name, rest |> Enum.join(" "))
  end

  def normalize_names_attr(attr) do
    attr
  end
end
