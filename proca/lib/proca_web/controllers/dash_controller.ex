defmodule ProcaWeb.DashController do
  use Phoenix.LiveView
  use ProcaWeb.Live.AuthHelper, otp_app: :proca

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "index.html", assigns)
  end

  def mount(params, session, socket) do
    socket = mount_user(socket, session)

    {:ok, assign(socket, :test, "pe")}
  end

  def session_expired(socket) do
    {:noreply, socket}
  end

end
