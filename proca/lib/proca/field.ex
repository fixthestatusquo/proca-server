defmodule Proca.Field do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.{Field,Action}

  schema "fields" do
    field :key, :string
    field :value, :string
    field :transient, :boolean
    belongs_to :action, Proca.Action
  end


  def changesets(custom_fields) when is_list(custom_fields) do
    custom_fields
    |> Enum.map(fn cf -> changeset(cf) end)
  end

  def changeset(attr = %{key: _key, value: _value}) do
    %Field{}
    |> cast(attr, [:key, :value, :transient], empty_values: [])
    # |> validate_required([:key, :value])
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

  def transient_fields(action = %Action{}) do
    from(f in Field, where: f.action_id == ^action.id and f.transient == true)
  end
end
