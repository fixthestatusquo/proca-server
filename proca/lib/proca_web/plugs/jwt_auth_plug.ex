defmodule ProcaWeb.Plugs.JwtAuthPlug do
  @moduledoc """
  A plug that reads JWT from Authorization header and authenticates the user.

  options:
  - query_param - specify if you want to fetch JWT from a query param
  - enable_session - set user also in phoenix session
  - email_path - list of keys to get email from in JWT (default ["email"])
  - email_verified_path = list of keys to get email verified info
  - external_id_path - list of keys to get external_id from JWT (default ["subject"])
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
    |> jwt_auth(opts)
    |> add_to_context()
    |> add_to_session(opts[:enable_session])
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def jwt_auth(conn, opts) do
    with token when not is_nil(token) <- get_token(conn, opts[:param]),
         {:ok, key} <- get_key(token),
         {:ok, claims} <- Joken.verify(token, key),
         email <- extract_field(claims, opts[:email_path] || ["email"]),
         external_id <- extract_field(claims, opts[:external_id_path] || ["sub"]),
         :ok <-
           check_email_verified(
             claims,
             opts[:email_verified_path] || ["user_metadata", "email_verified"]
           ) do
      conn
      |> get_or_create_user(email, external_id)
    else
      {:error, reason} ->
        error_halt(conn, 401, "unauthorized", "Cannot verify JWT token. #{reason}")

      :unverified ->
        error_halt(conn, 401, "unauthorized", "Email not verified")

      # no token
      nil ->
        conn
    end
  end

  def get_key(token) do
    with {:ok, %{"alg" => algo = "HS" <> _}} <- Joken.peek_header(token),
         secret when secret != nil <-
           Application.get_env(:proca, ProcaWeb.UserAuth)[:sso][:jwt_secret] do
      {:ok, Joken.Signer.create(algo, secret)}
    else
      {:ok, %{"alg" => algo}} -> {:error, "Unsupported JWT algorithm #{algo}"}
      nil -> {:error, "JWT not enabled"}
    end
  end

  def extract_field(_claims, nil), do: nil

  def extract_field(claims, path) do
    get_in(claims, path)
  end

  def check_email_verified(claims, path) do
    if need_verified_email?() do
      verified = extract_field(claims, path)

      if verified do
        :ok
      else
        :unverified
      end
    else
      :ok
    end
  end

  def get_or_create_user(conn, email, external_id) do
    attrs = %{
      email: email,
      external_id: external_id
    }

    user =
      Users.get_user_from_sso(email, external_id) ||
        Users.register_user_from_sso!(attrs)

    UserAuth.assign_current_user(conn, user)
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
