defmodule ProcaWeb.Resolvers.User do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query, only: [from: 2]
  import ProcaWeb.Helper, only: [format_errors: 1, msg_ext: 2]

  alias Proca.Auth
  alias Proca.Staffer

  import Proca.Repo
  import Ecto.Query, only: [from: 2]
  alias Proca.Staffer.Role
  alias Proca.Permission
  alias Proca.Users.User

  def staffer_role(staffer), do: Role.findrole(staffer) || "custom"

  def user_roles(user, _, _) do
    user = preload(user, staffers: :org)

    {
      :ok,
      Enum.map(user.staffers, fn stf ->
        %{
          role: staffer_role(stf),
          org: stf.org
        }
      end)
    }
  end

  def current_user(_, _, %{context: %{user: user}}) do
    {:ok, user}
  end

  defp can_remove_self?(user_or_staffer) do
    Permission.can?(user_or_staffer, :join_orgs)
  end

  defp existing(email, org) do
    user = User.one(email: email)

    if is_nil(user) do
      {nil, nil}
    else
      {user, Staffer.for_user_in_org(user, org.id)}
    end
  end

  @doc """
  User authorized to change_org_settings
  """
  def add_org_user(_, %{input: %{email: email, role: role_str}}, %{
        context: %{auth: auth, org: org}
      }) do
    with {user, staffer} when not is_nil(user) and is_nil(staffer) <- existing(email, org),
         role when role != nil <- Role.from_string(role_str),
         true <- Role.can_assign_role?(auth, role) do
      case insert(Staffer.changeset(%{user: user, org: org, role: role})) do
        {:ok, _} -> {:ok, %{status: :success}}
        {:error, _} = e -> e
      end
    else
      {nil, _} -> {:error, msg_ext("User does not exist", "not_found")}
      {_, %{}} -> {:ok, %{status: :noop}}
      false -> {:error, msg_ext("User must have higher role", "permission_denied")}
      nil -> {:error, msg_ext("No such role", "not_found")}
    end
  end

  def invite_org_user(_, params = %{input: %{email: email, role: role_str}}, %{
        context: %{auth: auth}
      }) do
    alias Proca.Confirm

    with role when role != nil <- Role.from_string(role_str),
         true <- Role.can_assign_role?(auth, role) do
      Confirm.AddStaffer.changeset(email, role, auth, params[:message])
      |> insert_and_notify()
    else
      false -> {:error, msg_ext("User must have higher role", "permission_denied")}
      nil -> {:error, msg_ext("No such role", "not_found")}
    end
  end

  def update_org_user(_, %{input: %{email: email, role: role_str}}, %{
        context: %{auth: auth, org: org}
      }) do
    with {user, staffer} when not is_nil(user) and not is_nil(staffer) <- existing(email, org),
         role when role != nil <- Role.from_string(role_str),
         true <- Role.can_assign_role?(auth, role) do
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

  defp update_user_by(criteria, params, auth) do
    if Permission.can?(auth, :manage_users) do
      q =
        case criteria do
          %{id: id} -> [id: id]
          %{email: email} -> [email: email]
          _ -> raise "Called #{__MODULE__}.update_user_by with neither id or email criteria"
        end

      case User.one(q) do
        nil -> {:error, "User not found"}
        user -> update(User.details_changeset(user, params))
      end
    else
      {:error, "Only admin with manage_users permission can modify other users"}
    end
  end

  def update_user(_, criteria = %{id: _id, input: input}, %{context: %{auth: auth}}) do
    update_user_by(criteria, input, auth)
  end

  def update_user(_, criteria = %{email: _email, input: input}, %{context: %{auth: auth}}) do
    update_user_by(criteria, input, auth)
  end

  def update_user(_, %{input: input}, %{context: %{auth: %Auth{user: user}}}) do
    user
    |> Proca.Users.User.details_changeset(input)
  end

  def delete_org_user(_, %{email: email}, %{context: %{auth: %Auth{user: actor}, org: org}}) do
    with {user, staffer} when not is_nil(user) and not is_nil(staffer) <- existing(email, org),
         true <- staffer.user_id != user.id or can_remove_self?(actor) do
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
    lst =
      from(s in Staffer, where: s.org_id == ^org.id, preload: [:user])
      |> all()
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

  def list_users(_, params, _) do
    criteria =
      params
      |> Map.get(:select, [])
      |> Enum.map(fn
        {:id, id} -> {:id, id}
        {:email, e} -> {:email_like, e}
        {:org_name, on} -> {:org_name, on}
      end)

    {:ok, User.all(criteria)}
  end

  def api_token(user, _, %{context: %{auth: %Auth{user: user}}}) do
    case Proca.Repo.one(Proca.Users.UserToken.user_and_contexts_query(user, ["api"])) do
      nil ->
        {:ok, nil}

      token ->
        {:ok,
         %{
           expires_at: Proca.Users.UserToken.expires_at(token)
         }}
    end
  end

  def api_token(_, _, _), do: {:ok, nil}
end
