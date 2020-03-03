defmodule ProcaWeb.PageController do
  use ProcaWeb, :controller

  def index(conn, _p) do
    render(conn, "index.html")
  end
end
