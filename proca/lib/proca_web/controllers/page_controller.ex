defmodule ProcaWeb.PageController do
  use ProcaWeb, :controller
  alias Proca.Staffer
  alias Proca.Repo
  import Ecto.Query

  def index(conn, params) do
    conn = switch_org(params, conn)

    orgs = Proca.Org.list

    user_orgs = if conn.assigns.user do
      from(st in Staffer, where: st.user_id == ^conn.assigns.user.id, select: st.org_id)
      |> Repo.all
    else
      []
    end

    staffer = if conn.assigns.user do
      Plug.Conn.get_session(conn, :staffer)
    else
      nil
    end
    
    render(conn, "index.html", %{
          staffer: staffer,
          orgs: orgs,
          user_orgs: user_orgs
           })
  end


  defp switch_org(%{"org_name" => org_name}, conn) do
    ProcaWeb.Plugs.StafferAuthPlug.switch_to_org(conn, :staffer, org_name) 
  end

  defp switch_org(_param, conn) do
    conn
  end
end
