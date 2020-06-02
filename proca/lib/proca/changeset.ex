defmodule Proca.Changeset do
  def trim(%Ecto.Changeset{changes: ch} = changeset,
    field, len) when is_atom(field) and is_integer(len) do

    case Map.get(ch, field, nil) do
      s when is_bitstring(s) ->
        Ecto.Changeset.put_change(changeset, field, String.slice(s, 0..(len-1)))
      nil -> changeset
    end
  end
end
