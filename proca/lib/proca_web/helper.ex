defmodule ProcaWeb.Helper do
  @moduledoc """
  Helper functions for formatting errors from resolvers
  """
  alias Ecto.Changeset
  import Ecto.Changeset
  alias Proca.{ActionPage, Campaign, Staffer}
  alias Proca.Staffer.Permission

  @doc """
  GraphQL expect a flat list of %{message: "some text"}. Traverse changeset and
  flat error messages to such list.

  The code will just show last field key for a nested record, so parent record
  name will not end up in messages. Maybe we should join all field names by a
  dot and return suchj field, for instance: contact.email instead of email
  """
  def format_errors(changeset) do
    changeset
    |> Changeset.traverse_errors(fn {msg, opts} -> %{message: replace_placeholders(msg, opts)} end)
    |> flatten_errors()
  end

  def replace_placeholders(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end



  @doc """
  Must be able to flatten an error structure like:
  %{fields: [%{value: [%{message: "can't be blank"}]}]}

  1. a list -> run recursively for each element, concatenate the result
  2. map with keys mapped to errors -> get each key and pass it futher
  """
  def flatten_errors(errors, path \\ [])

  # handle messages list (it's a list of %{message: "123"})
  def flatten_errors([], _), do: []

  def flatten_errors([%{message: msg} = m | other_msg], path = [lastkey | _])
       when map_size(m) == 1 do
    [%{
        message: "#{lastkey}: #{msg}",
        path: Enum.reverse(path)
     } | flatten_errors(other_msg, path)]
  end

  # handle an associated list (like has_many)
  def flatten_errors(lst, path) when is_list(lst) do
    lst
    |> Enum.with_index()
    |> Enum.map(fn {e, i} ->
      flatten_errors(e, [i | path])
    end)
    |> Enum.concat()
  end

  # handle an associated map (like has_one)
  def flatten_errors(map, path) when is_map(map) do
    map
    |> Map.keys()
    |> Enum.map(fn k ->
      flatten_errors(
        Map.get(map, k),
        [ProperCase.camel_case(k) | path]
      )
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

  def can_manage?(campaign = %Campaign{}, user, callback) do
    with org_id <- Map.get(campaign, :org_id),
         staffer <- Staffer.for_user_in_org(user, org_id),
         true <- Permission.can?(staffer, [:use_api, :manage_campaigns, :manage_action_pages]) do
      callback.(campaign)
    else
      _ -> {:error, "User cannot manage this campaign"}
    end
  end

  def can_manage?(action_page = %ActionPage{}, user, callback) do
    with org_id <- Map.get(action_page, :org_id),
         staffer <- Staffer.for_user_in_org(user, org_id),
         true <- Permission.can?(staffer, [:use_api, :manage_action_pages]) do
      callback.(action_page)
    else
      _ -> {:error, "User cannot manage this action page"}
    end
  end
end
