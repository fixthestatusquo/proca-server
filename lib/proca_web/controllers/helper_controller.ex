defmodule ProcaWeb.HelperController do
  use ProcaWeb, :controller

  @doc """
  XXX unused

  Noop call so client can refresh session timing out.

  See: https://github.com/danschultzer/pow/issues/271#issuecomment-587490766
  """
  def noop(conn, _o) do
    send_resp(conn, :ok, "")
  end
end
