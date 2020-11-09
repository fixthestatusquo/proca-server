defmodule ProcaWeb.Resolvers.Authorized do
  @moduledoc """
  Absinthe middleware to mark authenticated API calls.

  `middleware Authorized` - checks if context has :user
  `middleware Authorized` - can?: {:org | :campaign | :action_page, perms}, get_by: [:id, [name: :org_name]]

  """

  @behaviour Absinthe.Middleware

  alias Proca.Repo
  alias Proca.{Org, Campaign, ActionPage, Users.User, Staffer}
  import Ecto.Query

  def call(resolution, opts) do
    case resolution.context do
      %{user: user = %User{}} ->
        resolution
        |> verify_access(user, Keyword.get(opts, :can?), Keyword.get(opts, :get_by, [:id, :name]))

      _ ->
        resolution
        |> Absinthe.Resolution.put_result(
          {:error,
           %{
             message: "Authentication is required for this API call",
             extensions: %{code: "unauthorized"}
           }}
        )
    end
  end

  def verify_access(resolution, _user, nil, _) do
    resolution
  end

  def verify_access(resolution, user, {resource_type, perms}, by_fields) do
    case get_staffer_for_resource(user, resource_type, resolution.arguments, by_fields) do
      nil ->
        resolution
        |> Absinthe.Resolution.put_result(
          {:error,
           %{
             message: "User is not a member of team responsible for resource",
             extensions: %{
               code: "permission_denied"
             }
           }}
        )

      {staffer, resource} ->
        if Staffer.Permission.can?(staffer, perms) do
          %{
            resolution
            | context:
                resolution
                |> Map.put(:staffer, staffer)
                |> Map.put(resource_type, resource)
          }
        else
          resolution
          |> Absinthe.Resolution.put_result(
            {:error,
             %{
               message: "User does not have sufficient permissions",
               extensions: %{
                 code: "permission_denied",
                 required: perms
               }
             }}
          )
        end
    end
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
      join: c in Campaign,
      on: a.campaign_id == c.id,
      join: o in Org,
      on: c.org_id == o.id,
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
