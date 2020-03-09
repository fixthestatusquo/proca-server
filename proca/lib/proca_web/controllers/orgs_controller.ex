defmodule ProcaWeb.OrgsController do
  use Phoenix.LiveView
  use ProcaWeb.Live.AuthHelper, otp_app: :proca
  alias Proca.Org
  import Ecto.Query

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "orgs.html", assigns)
  end

  def handle_event("org_new", _value, socket) do
    {:noreply, assign(socket, :current_org, %Org{})}
  end

  def handle_event("org_discard", _value, socket) do
    {:noreply, assign(socket, :current_org, nil)}
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    orgs = Org.list([:public_keys])
    {:ok,
     socket
     |> assign(:orgs, orgs)
     |> assign(:current_org, nil)
    }
  end

  def session_expired(socket) do
    {:noreply, socket}
  end
end
