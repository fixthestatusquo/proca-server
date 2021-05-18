defmodule ProcaWeb.Resolvers.Authorized do
  @moduledoc """
  Absinthe middleware to mark authenticated API calls.

  `middleware Authorized` - checks if context has :user
  `middleware Authorized` - can?: perms, access: [:org | :campaign | :action_page, by: [:id, [name: :org_name]]]

  """

  @behaviour Absinthe.Middleware

  alias Proca.Repo
  alias Proca.{Org, Campaign, ActionPage, Users.User, Staffer}
  import Ecto.Query
  import ProcaWeb.Helper, only: [msg_ext: 3, cant_msg: 1, msg_ext: 2]

  def call(resolution, opts) do
    case resolution.context do
      %{user: user = %User{}} ->
        resolution
        |> verify_access(user, Keyword.get(opts, :access, :auth_only))
        |> verify_perms(Keyword.get(opts, :can?, nil))

      _ ->
        resolution
        |> Absinthe.Resolution.put_result(
          {:error, msg_ext("Authentication is required for this API call", "unauthorized")}
        )
    end
  end

  # No resource access requestesd. Just authenticated user
  def verify_access(resolution, _user, :auth_only) do
    resolution
  end

  def verify_access(resolution, user, [resource_type | opts]) do
    by_fields = Keyword.get(opts, :by, [:id, :name])
    case get_staffer_for_resource(user, resource_type, resolution.arguments, by_fields) do
      nil ->
        resolution
        |> Absinthe.Resolution.put_result(
          {:error, msg_ext("User is not a member of team responsible for resource","permission_denied")}
        )

      {staffer, resource} ->
          %{
            resolution
            | context:
                resolution.context
                |> Map.put(:staffer, staffer)
                |> Map.put(resource_type, resource)
          }
    end
  end

  def verify_perms(resolution, nil) do
    resolution
  end

  def verify_perms(resolution = %{state: :resolved}, _) do
    resolution
  end

  def verify_perms(resolution = %{context: %{staffer: staffer}}, perms) do
    if Staffer.Permission.can?(staffer, perms) do
      resolution
    else
      resolution
      |> Absinthe.Resolution.put_result(
        {:error, cant_msg(perms)}
      )
    end
  end

  def verify_perms(resolution = %{context: %{}}, _perms) do
    resolution
    |> Absinthe.Resolution.put_result({
        :error, msg_ext("No object accessed, thus no permission can be verified", "permission_denied")
      })
  end

  def get_staffer_for_resource(user, :instance_org, _args, _by_fields) do
    query_for(user, :org)
    |> get_by(:name, Application.get_env(:proca, Proca)[:org_name])
    |> Repo.one()
  end

  def get_staffer_for_resource(user, resource_type, args, [{f, a} | by_fields]) do
    case Map.get(args, a, nil) do
      nil ->
        get_staffer_for_resource(user, resource_type, args, by_fields)

      value ->
        query_for(user, resource_type)
        |> get_by(f, value)
        |> Repo.one()
    end
  end

  def get_staffer_for_resource(user, rt, args, [fa | by_fields]) do
    get_staffer_for_resource(user, rt, args, [{fa, fa} | by_fields])
  end

  def get_staffer_for_resource(_, _, _, []) do
    nil
  end

  def query_for(user, :org) do
    from(
      o in Org,
      join: s in Staffer,
      on: s.org_id == o.id,
      where: s.user_id == ^user.id,
      select: {s, o}
    )
  end

  def query_for(user, :campaign) do
    from(
      c in Campaign,
      join: o in Org,
      on: c.org_id == o.id,
      join: s in Staffer,
      on: s.org_id == o.id,
      where: s.user_id == ^user.id,
      select: {s, c}
    )
  end

  def query_for(user, :action_page) do
    from(
      a in ActionPage,
      join: o in Org,
      on: a.org_id == o.id,
      join: s in Staffer,
      on: s.org_id == o.id,
      where: s.user_id == ^user.id,
      select: {s, a}
    )
  end

  def get_by(query, :id, value) do
    where(query, [r], r.id == ^value)
  end

  def get_by(query, :name, value) do
    where(query, [r], r.name == ^value)
  end
end
