defmodule ProcaWeb.DashController do
  use ProcaWeb, :live_view

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "index.html", assigns)
  end

  def mount(_params, session, socket) do
    IO.inspect(session, label: "Session in dash")
    socket = mount_user(socket, session)
    IO.inspect(socket.assigns, label: "Live assigns")

    {:ok, assign(socket, :test, "pe")}
  end
end
