# XXX rename to HomeController or something
defmodule ProcaWeb.PageController do
  use ProcaWeb, :controller

  alias Proca.Staffer
  alias Proca.Repo
  alias ProcaWeb.Controller.AuthHelper
  import Ecto.Query

  def index(conn, _params) do
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
end
