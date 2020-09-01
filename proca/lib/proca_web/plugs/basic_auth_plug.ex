defmodule ProcaWeb.Plugs.BasicAuthPlug do
  @behaviour Plug

  alias Plug.Conn
  alias Pow.{Plug, Store.CredentialsCache}
  alias Proca.Users.User


 #   Absinthe.Plug.put_options(conn, context: context)
  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> basic_auth()
    |> add_to_context()
  end

  @doc """
  Return the current user context based on the authorization header
  """
  def basic_auth(conn) do
    case Conn.get_req_header(conn, "authorization") do
      # Basic Auth
      ["Basic " <> token] -> try_authorize(token, conn)
      |> Conn.delete_req_header("authorization")
        
      # not Basic authorization
      _ -> conn
    end
  end

  defp try_authorize(token, conn) do
    with {:ok, dec_tok} <- Base.decode64(token),
         [email, pass] <- String.split(dec_tok, ":", parts: 2),
         {:ok, conn} <- Plug.authenticate_user(conn, %{"email" => email, "password" => pass}) do
      conn
    else
      {:error, conn = %Conn{}} -> conn
      |> Conn.send_resp(401, "Unauthorized")
      |> Conn.halt()

      _ -> conn
      |> Conn.send_resp(401, "Malformed authorization")
      |> Conn.halt()
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
