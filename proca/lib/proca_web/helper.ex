defmodule ProcaWeb.Helper do
  alias Ecto.Changeset
  import Ecto.Changeset

  @doc """
  GraphQL expect a flat list of %{message: "some text"}. Traverse changeset and
  flat error messages to such list.

  The code will just show last field key for a nested record, so parent record
  name will not end up in messages. Maybe we should join all field names by a
  dot and return suchj field, for instance: contact.email instead of email
  """

  def format_errors(changeset) do
    changeset
    |> Changeset.traverse_errors(fn {msg, _o} -> %{message: msg} end)
    |> flatten_errors()
  end


  defp flatten_errors(%{} = map) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(fn k ->
      flatten_errors(Map.get(map, k), k)
    end)
    |> Enum.concat()
  end

  defp flatten_errors(%{message: msg} = map, lastkey) when is_map(map) do
    [%{message: "#{lastkey}: #{msg}", path: [Atom.to_string(lastkey)]}]
  end

  defp flatten_errors(lst, lastkey) when is_list(lst) do
    Enum.map(lst, fn e ->
      flatten_errors(e, lastkey)
    end)
    |> Enum.concat()
  end

  @spec validate(Ecto.Changeset.t) :: {:ok | :error, Ecto.Changeset.t}
  def validate(changeset) do
    case changeset do
      ch = %{valid?: true} -> {:ok, apply_changes(ch)}
      errch -> {:error, errch}
    end
  end

end
