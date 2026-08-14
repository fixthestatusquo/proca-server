defmodule ProcaWeb.Plugs.JwtAuthPlug do
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
  alias Proca.Server.Jwks
  import ProcaWeb.Plugs.Helper

  def init(opts) do
    opts
  end

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
    jwt_opts = Application.get_env(:proca, ProcaWeb.UserAuth)[:sso][:jwt]

    with token when not is_nil(token) <- get_token(conn, opts[:param]),
         {:ok, key} <- get_key(token),
         {:ok, claims} <- Joken.verify(token, key),
         email <- extract_field(claims, jwt_opts[:email_path] || ["email"]),
         external_id <- extract_field(claims, jwt_opts[:external_id_path] || ["sub"]),
         :ok <- if(is_nil(email), do: :invalid, else: :ok),
         :ok <- check_expiry(claims),
         :ok <-
           check_email_verified(
             claims,
             jwt_opts[:email_verified_path] || ["user_metadata.email_verified"]
           ) do
      conn
      |> get_or_create_user(email, external_id)
    else
      {:error, reason} ->
        error_halt(conn, 401, "unauthorized", "Cannot verify JWT token. #{reason}")

      :unverified ->
        error_halt(conn, 401, "unauthorized", "Email not verified")

      :expired ->
        error_halt(conn, 401, "unauthorized", "JWT expired")

      :invalid ->
        error_halt(conn, 401, "unauthorized", "JWT is invalid (missing values)")

      # no token
      nil ->
        conn
    end
  end

  def get_key(token) do
    case Joken.peek_header(token) do
      {:ok, %{"alg" => algo = "HS" <> _}} -> get_key_secret(algo)
      {:ok, %{"alg" => algo = "RS" <> _, "kid" => key_id}} -> get_key_jwks(algo, key_id)
      {:ok, %{"alk" => algo}} -> {:error, "Unsupported JWT algorithm #{algo}"}
    end
  end

  def get_key_secret(algo) do
    case Application.get_env(:proca, ProcaWeb.UserAuth)[:sso][:jwt_secret] do
      nil -> {:error, "JWT not enabled for symmetric keys (#{algo})"}
      secret -> {:ok, Joken.Signer.create(algo, secret)}
    end
  end

  def get_key_jwks(algo, key_id) do
    case Jwks.key(key_id) do
      nil ->
        {:error, "JWT not enabled for asymmetric keys (#{algo})"}

      key ->
        {:ok, Joken.Signer.create(algo, key)}
    end
  end

  @doc """
  extract field from nested map, using a path to fetch key:

  eg. session.identity.emails.[].email
  use [] to access an array (fetching first result)

  Pass a list of paths to try all of them.
  """
  def extract_field(_claims, nil), do: nil
  def extract_field(_claims, []), do: nil
  def extract_field(nil, _path), do: nil

  def extract_field(claims, paths = [path | rest]) when is_list(paths) and is_bitstring(path) do
    extract_field(claims, path) || extract_field(claims, rest)
  end

  def extract_field(claims, path) do
    path = String.split(path, ~r/[. ]/)

    all = fn :get, lst, next ->
      case lst do
        lst when is_list(lst) -> Enum.map(lst, next)
        _ -> nil
      end
    end

    path =
      Enum.map(path, fn
        "[]" -> all
        s -> s
      end)

    get_in(claims, path)
    |> List.wrap()
    |> List.flatten()
    |> List.first()
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

  def check_expiry(claims) do
    with {:ok, exp} <- DateTime.from_unix(Map.get(claims, "exp")),
         :gt <- DateTime.compare(exp, DateTime.utc_now()) do
      :ok
    else
      _ -> :expired
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

  # heuristic that jwt token must start with ey - base64 for {"
  defp get_token(conn, nil) do
    case Conn.get_req_header(conn, "authorization") do
      ["Bearer ey" <> token] -> "ey" <> token
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
    Application.get_env(:proca, ProcaWeb.UserAuth)[:require_verified_email]
  end
end
