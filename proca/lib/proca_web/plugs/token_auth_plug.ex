defmodule ProcaWeb.Plugs.TokenAuthPlug do
  @moduledoc """
  A plug that reads JWT from Authorization header and authenticates the user.

  options:
  - query_param - specify if you want to fetch JWT from a query param
  - enable_session - set user also in phoenix session
  - email_path - list of keys to get email from in JWT (default ["email"])
  - email_verified_path = list of keys to get email verified info (default user_metadata.email_verified)
  - external_id_path - list of keys to get external_id from JWT (default ["sub"])
  """
  @behaviour Plug

  alias Plug.Conn
  alias Proca.Auth
  alias ProcaWeb.UserAuth
  alias Proca.Users
  alias Proca.Users.User
  import ProcaWeb.Plugs.Helper

  def init(opts) do
    opts
  end

  def call(conn, opts) do
    conn
    |> token_auth(opts)
    |> add_to_context()
    |> add_to_session(opts[:enable_session])
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def token_auth(conn, _opts) do
    with token when not is_nil(token) <- get_token(conn),
         {:user, %User{} = user} <- {:user, Users.get_user_by_api_token(token)} do
      UserAuth.assign_current_user(conn, user)
    else
      {:user, nil} -> error_halt(conn, 401, "unauthorized", "Cannot verify token")
      nil -> conn
    end
  end

  defp get_token(conn) do
    case Conn.get_req_header(conn, "authorization") do
      ["Bearer API-" <> token] -> "API-" <> token
      _ -> nil
    end
  end

  defp add_to_context(conn) do
    case conn.assigns[:user] do
      %User{} = u ->
        Absinthe.Plug.assign_context(conn, %{
          # XXX for backward compatibility
          user: u,
          auth: %Auth{user: u}
        })

      nil ->
        conn
    end
  end

  defp add_to_session(conn, nil), do: conn

  defp add_to_session(conn, false), do: conn

  defp add_to_session(conn, true) do
    case conn.assigns[:user] do
      user = %User{} -> UserAuth.log_in_user(conn, user)
      nil -> conn
    end
  end
end
