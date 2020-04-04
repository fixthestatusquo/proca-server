defmodule ProcaWeb.Plugs.ApiAuthPlug do
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
    with ["Basic " <> token] <- Conn.get_req_header(conn, "authorization"),
         {:ok, conn} <- authenticate(token, conn)
      do
      conn
    else
      _ -> conn
    end
  end

  defp authenticate(token, conn) do
    with {:ok, dec_tok} <- Base.decode64(token),
         [email, pass] <- String.split(dec_tok, ":", parts: 2),
         {:ok, conn} <- Plug.authenticate_user(conn, %{"email" => email, "password" => pass}) do
      {:ok, conn}
    else
        _ -> :error
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
