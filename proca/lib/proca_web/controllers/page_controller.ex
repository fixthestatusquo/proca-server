# XXX rename to HomeController or something
defmodule ProcaWeb.PageController do
  use ProcaWeb, :controller

  alias Proca.Staffer
  alias Proca.Repo
  alias ProcaWeb.Controller.AuthHelper
  import Ecto.Query

  def index(conn, params) do
    conn = signin(conn, params["org_name"])

    user_orgs =
      if conn.assigns[:user] do
        from(st in Staffer, where: st.user_id == ^conn.assigns.user.id, select: st.org_id)
        |> Repo.all()
      else
        []
      end

    render(conn, "index.html", %{
      staffer: conn.assigns[:staffer],
      user_orgs: user_orgs
  })
  end


  defp signin(conn, org_name) do
    pow_config = Application.get_env(:proca, :pow)

    with {user, staffer} <- AuthHelper.current_user(conn, get_session(conn), pow_config, org_name) do
      conn
      |> assign(:user, user)
      |> assign(:staffer, staffer)
    else
      _ -> conn
    end
  end
end
