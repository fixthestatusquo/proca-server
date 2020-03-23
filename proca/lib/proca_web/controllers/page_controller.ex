defmodule ProcaWeb.PageController do
  use ProcaWeb, :controller


  def index(conn, params) do
    IO.inspect params

    conn = switch_org(params, conn)
    ol = Proca.Org.list
    render(conn, "index.html", %{ org_list: ol })
  end


  defp switch_org(%{"org_name" => org_name}, conn) do
    ProcaWeb.Plugs.StafferAuthPlug.switch_to_org(conn, :staffer, org_name) 
  end

  defp switch_org(_param, conn) do
    conn
  end
end
