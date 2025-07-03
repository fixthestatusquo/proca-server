defmodule Proca.Field do
  @moduledoc """
  Custom field helpers (to support deprecated Field model)
  """

  @doc """
  Converts list of key->value to a map, and if some key is present more then once, the values will be aggregated in an array.
  """
  def list_to_map(fields) do
    fields
    |> Enum.reduce(%{}, fn %{key: k, value: v}, acc ->
      Map.update(acc, k, v, fn
        l when is_list(l) -> [v | l]
        v2 -> [v, v2]
      end)
    end)
  end

  def map_to_list(field_map) do
    Enum.map(field_map, fn {k, v} ->
      if is_list(v) do
        Enum.map(v, fn vi -> %{key: k, value: "#{vi}"} end)
      else
        [%{key: k, value: "#{v}"}]
      end
    end)
    |> List.flatten()
  end
end
