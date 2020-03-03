defmodule ProcaWeb.PageController do
  use ProcaWeb, :controller


  def index(conn, _p) do
    ol = Proca.Org.list
    render(conn, "index.html", %{ org_list: ol })
  end
end
