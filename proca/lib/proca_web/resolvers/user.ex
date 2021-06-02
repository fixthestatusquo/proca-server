defmodule ProcaWeb.Resolvers.User do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query, only: [from: 2]
  import Ecto.Changeset
  import ProcaWeb.Helper, only: [format_errors: 1, msg_ext: 2, cant_msg: 1, format_result: 1]

  alias Proca.{ActionPage, Campaign, Action}
  alias Proca.{Org, Staffer, PublicKey}
  alias ProcaWeb.Helper

  import Proca.Repo
  import Ecto.Query, only: [from: 2]
  alias Proca.Staffer.{Permission, Role}
  alias Proca.Users.User

  import Logger

  def staffer_role(staffer), do: Role.findrole(staffer) || "custom"

  def user_roles(user) do 
    user = preload(user, [staffers: :org])

    %{
      id: user.id,
      email: user.email,
      roles: Enum.map(user.staffers, fn stf ->
        %{
          role: staffer_role(stf),
          org: stf.org
        }
      end)
    }
  end


  def current_user(_, _, %{context: %{user: user}}) do

    {:ok, user_roles(user)}
  end

  defp can_assign_role?(%Staffer{perms: perms}, role) do 
    Role.permissions(role) -- Permission.to_list(perms) == []
  end

  defp can_remove_self?(staffer) do 
    Permission.can? staffer, :join_orgs
  end


  defp existing(email, org) do 
    user = get_by(User, email: email)
    if is_nil(user) do 
      {nil, nil}
    else
      {user, Staffer.for_user_in_org(user, org.id)}
    end
  end


  @doc """
  User authorized to change_org_settings
  """
  def add_org_user(_, %{input: %{email: email, role: role_str}}, %{context: %{staffer: manager, org: org}}) do 
    with  {user, staffer} when not is_nil(user) and is_nil(staffer)  <- existing(email, org),
          role when role != nil <- Role.from_string(role_str),
          true <- can_assign_role?(manager, role)
    do 
      case Staffer.build_for_user(user, org.id, Role.permissions(role)) |> insert() do 
        {:ok, _} -> {:ok, %{status: :success}}
        {:error, e} -> {:error, format_errors(e)}
      end

    else 
      {nil, _} -> {:error, msg_ext("User does not exist", "not_found")}
      {_, %{}} -> {:ok, %{status: :noop}}
      false -> {:error, msg_ext("User must have higher role", "permission_denied")}
      nil -> {:error, msg_ext("No such role", "not_found")}
    end
  end

  def update_org_user(_, %{input: %{email: email, role: role_str}}, %{context: %{staffer: manager, org: org}}) do 
    with  {user, staffer} when not is_nil(user) and not is_nil(staffer)  <- existing(email, org),
          role when role != nil <- Role.from_string(role_str),
          true <- can_assign_role?(manager, role)
    do
      case Role.change(staffer, role) |> update() do 
        {:ok, _} -> {:ok, %{status: :success}}
        {:error, e} -> {:error, format_errors(e)}
      end
    else 
      {nil, _} -> {:error, msg_ext("User does not exist", "not_found")}
      {%{}, nil} -> {:error, msg_ext("User is not a member of this org", "not_found")}
      false -> {:error, msg_ext("User must have higher role", "permission_denied")}
      nil -> {:error, msg_ext("No such role", "not_found")}
    end
  end

  def delete_org_user(_,  %{email: email}, %{context: %{staffer: manager, org: org}}) do 
    with  {user, staffer} when not is_nil(user) and not is_nil(staffer)  <- existing(email, org),
      true <- staffer.id != manager.id or can_remove_self?(manager)
    do
      case delete(staffer) do
        {:ok, _} -> {:ok, %{status: :success}}
        {:error, e} -> {:error, format_errors(e)}
      end
    else 
      {nil, _} -> {:error, msg_ext("User does not exist", "not_found")}
      {%{}, nil} -> {:error, msg_ext("User is not a member of this org", "not_found")}
      false -> {:Error, msg_ext("You cannot remove yourself", "permission_denied")}
    end
  end

  def list_org_users(org, _, _) do 
    lst = from(s in Staffer, where: s.org_id == ^org.id, preload: [:user])
    |> all()
    |> IO.inspect()
    |> Enum.map(fn st -> 
      %{
        email: st.user.email,
        role: staffer_role(st),
        created_at: st.user.inserted_at,
        joined_at: st.inserted_at,
        last_signin_at: st.last_signin_at
      }
      end)
    {:ok, lst}
  end

end
