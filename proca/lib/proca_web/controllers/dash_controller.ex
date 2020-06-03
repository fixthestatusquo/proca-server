defmodule ProcaWeb.DashController do
  use ProcaWeb, :live_view

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "index.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    {:ok, assign(socket, :test, "pe")}
  end
end
