defmodule ProcaWeb.Plugs.JwtAuthPlug do
  @moduledoc """
  A plug that reads JWT from Authorization header and authenticates the user
  """
  @behaviour Plug

  alias Plug.Conn
  alias Proca.Auth
  alias ProcaWeb.UserAuth
  alias Proca.Users
  alias Proca.Users.User
  import ProcaWeb.Plugs.Helper

  def init(opts), do: opts

  def call(conn, opts) do
    conn
    |> jwt_auth(opts[:query_param])
    |> add_to_context()
    |> add_to_session(opts[:enable_session])
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def jwt_auth(conn, param) do
    with token when not is_nil(token) <- get_token(conn, param),
         {true, jwt, _sig} <- Proca.Server.Jwks.verify(token),
         true <- check_has_session(jwt),
         :ok <- check_email_verified(jwt) do
      conn
      |> get_or_create_user(jwt)
    else
      {false, _, _} ->
        error_halt(conn, 401, "unauthorized", "JWT token invalid")

      :unverified ->
        error_halt(conn, 401, "unauthorized", "Email not verified")

      # token with no identity traits
      false ->
        error_halt(conn, 401, "unauthorized", "JWT token has invalid data")

      # no token
      nil ->
        conn
    end
  end

  def check_has_session(%JOSE.JWT{
        fields: %{
          "session" => %{
            "identity" => %{
              "traits" => %{"email" => _email},
              "verifiable_addresses" => _emails
            }
          }
        }
      }),
      do: true

  def check_has_session(_), do: false

  def check_email_verified(jwt) do
    if need_verified_email?() do
      current =
        case jwt do
          %JOSE.JWT{
            fields: %{
              "session" => %{
                "identity" => %{
                  "traits" => %{"email" => email},
                  "verifiable_addresses" => emails
                }
              }
            }
          } ->
            Enum.find(emails, fn %{"value" => v} -> v == email end)

          _ ->
            %{}
        end

      if current["verified"] do
        :ok
      else
        :unverified
      end
    else
      :ok
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
        case Users.get_user_by_email(email) do
          nil ->
            UserAuth.assign_current_user(conn, Users.register_user_from_sso!(%{email: email}))

          user ->
            UserAuth.assign_current_user(conn, user)
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

  defp need_verified_email? do
    Application.get_env(:proca, Proca)[:require_verified_email]
  end
end
