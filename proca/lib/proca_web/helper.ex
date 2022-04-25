defmodule ProcaWeb.Helper do
  @moduledoc """
  Helper functions for formatting errors from resolvers
  """
  alias Ecto.Changeset
  import Ecto.Changeset
  alias Proca.{ActionPage, Campaign, Staffer}
  alias Proca.Permission
  alias ProcaWeb.Error

  def format_result({:ok, value}), do: {:ok, value}

  def fromat_result({:error, changeset = %Ecto.Changeset{}}),
    do: {:error, format_errors(changeset)}

  @doc """
  GraphQL expect a flat list of %{message: "some text"}. Traverse changeset and
  flat error messages to such list.

  The code will just show last field key for a nested record, so parent record
  name will not end up in messages. Maybe we should join all field names by a
  dot and return suchj field, for instance: contact.email instead of email
  """
  def format_errors(changeset, path \\ []) do
    changeset
    |> Changeset.traverse_errors(fn {msg, opts} -> %{message: replace_placeholders(msg, opts)} end)
    |> flatten_errors(path)
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

  def flatten_errors([%{message: msg} = m | other_msg], path)
      when map_size(m) == 1 do
    [
      %{
        message: msg,
        path: Enum.reverse(path)
      }
      | flatten_errors(other_msg, path)
    ]
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

  @spec validate(Ecto.Changeset.t()) :: {:ok | :error, Ecto.Changeset.t()}
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

  def cant_msg(perms),
    do: %Error{
      message: "User does not have sufficient permissions",
      code: "permission_denied",
      context: [required: perms]
    }

  def msg_ext(msg, code, ext \\ %{}),
    do: %Error{
      message: msg,
      code: code,
      context: Enum.into(ext, [])
    }

  def has_error?(errors, field, msg)
      when is_list(errors) and is_atom(field) and is_bitstring(msg) do
    errors
    |> Enum.any?(fn
      {^field, {^msg, _}} -> true
      _ -> false
    end)
  end

  def request_basic_auth(conn, msg) do
    conn
    |> Plug.Conn.put_resp_header("WWW-Authenticate", "Basic realm=\"Proca\"")
    |> Plug.Conn.resp(401, msg)
  end

  def rename_key(map, k1, k2) do
    case Map.pop(map, k1) do
      {nil, m} -> m
      {v, m} -> Map.put(m, k2, v)
    end
  end
end

# XXX not sure if best place for this
# defimpl Inspect, for: Absinthe.Resolution do
#   def inspect(resolution, _opts) do
#     show_only = Map.take(resolution, [:value, :errors, :state, :arguments, :context])
#     |> Enum.to_list()
#
#     "#Absinthe.Resolution<#{inspect(show_only)}>"
#   end
# end
