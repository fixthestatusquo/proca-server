defmodule ProcaWeb.TeamController do
  use Phoenix.LiveView
  use ProcaWeb.Live.AuthHelper, otp_app: :proca
  alias Proca.{Org,Staffer}
  alias Proca.Repo
  alias Ecto.Changeset
  import Ecto.Query
  
  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "team.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    {:ok,
     socket
     |> assign_staffers(socket.assigns[:staffer].org_id)
    }
  end

  def assign_staffers(socket, org_id) do
    socket
    |> assign(:staffers, Staffer.get_by_org(org_id))
  end

  def session_expired(socket) do
    {:noreply, socket}
  end
end
