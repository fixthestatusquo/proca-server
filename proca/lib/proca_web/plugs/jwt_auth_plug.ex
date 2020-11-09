defmodule ProcaWeb.Plugs.JwtAuthPlug do
  @moduledoc """
  A plug that reads JWT from Authorization header and authenticates the user
  """
  @behaviour Plug

  alias Plug.Conn
  alias Pow.{Plug, Plug.Session}
  alias Proca.Users.User
  alias Proca.Repo
  alias Proca.Users.User
  import ProcaWeb.Plugs.Helper

  @pow_config [otp_app: :proca]

  #   Absinthe.Plug.put_options(conn, context: context)
  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> jwt_auth(opts[:query_param])
    |> add_to_context
    |> add_to_session(opts[:enable_session])
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def jwt_auth(conn, param) do
    with token when not is_nil(token) <- get_token(conn, param),
         {true, jwt, _sig} <- Proca.Server.Jwks.verify(token) do
      conn
      |> get_or_create_user(jwt)
    else
      {false, _, _} ->
        error_halt(conn, 401, "unauthorized", "JWT token invalid")

      # no token
      nil ->
        conn
    end
  end

  def get_or_create_user(conn, jwt) do
    case jwt do
      %JOSE.JWT{
        fields: %{
          "session" => %{
            "identity" => %{
              "traits" => %{"email" => email}
            }
          }
        }
      } ->
        case Repo.get_by(User, email: email) do
          nil -> Plug.assign_current_user(conn, User.create(email), User.pow_config())
          user -> Plug.assign_current_user(conn, user, User.pow_config())
        end

      _ ->
        conn
    end
  end

  defp get_token(conn, nil) do
    case Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> token
      _ -> nil
    end
  end

  defp get_token(conn, param) do
    conn = Conn.fetch_query_params(conn)
    conn.query_params[param]
  end

  defp add_to_context(conn) do
    case conn.assigns.user do
      %User{} = u ->
        Absinthe.Plug.put_options(conn, context: %{user: u})

      nil ->
        conn
    end
  end

  defp add_to_session(conn, nil), do: conn

  defp add_to_session(conn, false), do: conn

  defp add_to_session(conn, true) do
    case conn.assigns.user do
      user = %User{} -> conn |> Session.create(user, @pow_config) |> elem(0)
      _ -> conn
    end
  end
end
