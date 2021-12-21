defmodule ProcaWeb.Resolvers.AuthAllow do
  @behaviour Absinthe.Middleware
  alias Absinthe.Resolution
  alias Proca.Users.User
  alias Proca.Staffer
  alias Proca.Auth

  import Proca.Permission, only: [can?: 2, to_list: 1]

  @impl true
  def call(r = %Resolution{state: :resolved}, _), do: r

  @impl true
  def call(resolution = %{context: %{user: %User{}}}, :user) do
    resolution
  end

  @impl true
  def call(resolution, :user) do
    Resolution.put_result(resolution,
      {:error, %ProcaWeb.Error{
          code: "unauthorized",
          message: "Authentication is required for this API call"}})
  end

  @impl true
  def call(resolution = %{context: %{auth: %Auth{staffer: %Staffer{}}}}, :staffer) do
    resolution
  end

  @impl true
  def call(resolution, :staffer) do
    IO.inspect Map.keys(resolution.context )
    Resolution.put_result(resolution,
      {:error, %ProcaWeb.Error{
          code: "unauthorized",
          message: "User is not a member of organisation"}})
  end

  @impl true
  def call(resolution = %{context: %{auth: auth}}, perms) when is_list(perms) do
    if Enum.any?([:instance_owner | perms], fn p -> can?(auth, p) end) do
      resolution
    else
        Resolution.put_result(resolution,
          {:error, %ProcaWeb.Error{
              code: "permission_denied",
              message: "You do not have the required permission",
              context: [required: perms, provided: perms_list(auth)] ++ org_info(auth)}})
    end
  end

  @impl true
  def call(resolution, _perms) do
    Resolution.put_result(resolution,
      {:error, %ProcaWeb.Error{
          code: "permission_denied",
          message: "User is not a member of team responsible for resource"}})
  end

  defp perms_list(%Auth{user: user, staffer: staffer}) do
    to_list(user.perms) ++ case staffer do
                             nil -> []
                             %{perms: p} -> to_list(p)
                           end
  end

  defp org_info(%Auth{staffer: %{org_id: org_id}}), do: [org_id: org_id]
  defp org_info(_), do: []

end
