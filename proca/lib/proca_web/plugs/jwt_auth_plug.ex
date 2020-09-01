defmodule ProcaWeb.Plugs.JwtAuthPlug do
  @behaviour Plug

  alias Plug.Conn
  alias Pow.{Plug, Plug.Session}
  alias Proca.Users.User
  alias Proca.Repo
  alias Proca.Users.User

  @pow_config pow_config  = [otp_app: :proca]

 #   Absinthe.Plug.put_options(conn, context: context)
  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> jwt_auth()
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def jwt_auth(conn) do
    with [token] <- Conn.get_req_header(conn, "authorization"),
         {true, jwt, _sig} <- Proca.Server.Jwks.verify(token)
      do
      IO.inspect(jwt, label: "JWT success")
      conn
      |> get_or_create_user(jwt)
      |> add_to_context
    else
      {false, _, _} -> conn
      |> Conn.send_resp(401, "Unauthorized")
      |> Conn.halt()
      _ -> conn
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
      } -> case Repo.get_by(User, email: email) do
             nil -> Session.do_create(conn, User.params_for(email), @pow_config)
             user -> Plug.assign_current_user(conn, user, @pow_config)
           end

      _ -> nil
    end
  end

  defp add_to_context(conn) do
    case conn.assigns.user do
      %User{} = u -> 
        Absinthe.Plug.put_options(conn, context: %{user: u})
      nil -> conn
    end
  end
end
