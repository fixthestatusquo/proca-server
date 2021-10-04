defmodule ProcaWeb.Plugs.BasicAuthPlug do
  @moduledoc """
  A plug that reads JWT from Authorization header and authenticates the user
  """
  @behaviour Plug

  alias Plug.Conn
  alias Proca.Auth
  alias Proca.Users
  alias Proca.Users.User
  alias ProcaWeb.UserAuth
  import ProcaWeb.Plugs.Helper

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
      # not Basic authorization
      _ -> conn
    end
  end

  defp try_authorize(token, conn) do
    with {:ok, dec_tok} <- Base.decode64(token),
         [email, pass] when email != "" and pass != "" <- String.split(dec_tok, ":", parts: 2),
         user = %User{} <- Users.get_user_by_email_and_password(email, pass) do
      conn
      |> UserAuth.assign_current_user(user)
    else
      nil ->
        conn
        |> error_halt(
          401,
          "unauthorized",
          "Can not authenticate with these Basic HTTP credentials"
        )

      _ ->
        conn
        |> error_halt(400, "unauthorized", "Malformed Basic auth header")
    end
  end

  defp add_to_context(conn) do
    case conn.assigns[:user] do
      %User{} = u ->
        Absinthe.Plug.assign_context(conn, %{
          user: u, # XXX for backward compatibility
          auth: %Auth{user: u}
        })

      nil ->
        conn
    end
  end
end
