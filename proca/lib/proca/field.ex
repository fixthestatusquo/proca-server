defmodule Proca.Field do
  use Ecto.Schema
  import Ecto.Changeset
  alias Proca.Field

  schema "fields" do
    field :key, :string
    field :value, :string
    belongs_to :action, Proca.Action
  end


  def changesets(custom_fields) when is_list(custom_fields) do
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

  @doc """
  Converts list of key->value to a map, and if some key is present more then once, the values will be aggregated in an array.
  """
  def list_to_map(fields) do
    fields
    |> Enum.reduce(%{}, fn %{key: k, value: v},
      acc ->
        Map.update(acc, k, v, fn
          l when is_list(l) -> [v | l]
          v2 -> [v, v2]
        end)
    end)
  end
end
