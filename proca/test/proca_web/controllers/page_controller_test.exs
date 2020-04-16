defmodule ProcaWeb.PageControllerTest do
  use ProcaWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "<title>Proca</title>"
  end
end
