defmodule Proca.Field do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Field

  schema "fields" do
    field :key, :string
    field :value, :string
    belongs_to :action, Proca.Action
    belongs_to :source, Proca.Source
  end


  def changesets(custom_fields) do
    custom_fields
    |> Enum.map(fn cf -> changeset(cf) end)
  end

  def changeset(attr = %{key: _key, value: _value}) do
    %Field{}
    |> cast(attr, [:key, :value])
    |> validate_format(:key, ~r/^([\w\d_-]+$)/)
    |> validate_length(:key, min: 1, max: 64)
    |> validate_length(:value, max: 1024)
  end
end
