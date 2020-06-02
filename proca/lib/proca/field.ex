defmodule Proca.Field do
  use Ecto.Schema
  import Ecto.Changeset
  import Proca.Changeset
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
    |> trim(:key, 255)
    |> trim(:value, 255)
  end
end
