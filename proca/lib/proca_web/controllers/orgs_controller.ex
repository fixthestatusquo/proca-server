defmodule ProcaWeb.OrgsController do
  use Phoenix.LiveView
  use ProcaWeb.Live.AuthHelper, otp_app: :proca
  alias Proca.Org
  alias Proca.Repo
  import Ecto.Query

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "orgs.html", assigns)
  end

  def handle_event("org_new", _value, socket) do
    {:noreply,
     socket
     |> assign(:change_org, Org.changeset(%Org{}, %{}))
     |> assign(:can_remove_org, false)
    }
  end

  def handle_event("org_discard", _value, socket) do
    {:noreply,
     socket
     |> assign(:change_org, nil)
    }
  end

  def handle_event("org_edit", %{"id" => id}, socket) do
    org = Repo.get Org, String.to_integer(id)
    {:noreply,
     socket
     |> assign(:change_org, Org.changeset(org, %{}))
     |> assign(:can_remove_org, false)
    }
  end

  def handle_event("org_remove_lock", _v, socket) do
    {
      :noreply,
      socket
      |> assign(:can_remove_org, not socket.assigns[:can_remove_org])
    }
  end

  def handle_event("org_remove", %{"id" => id}, socket) do
    Repo.delete %Org{id: String.to_integer(id)}
    {
      :noreply,
      socket
      |> assign(:change_org, nil)
      |> assign_org_list
    }
  end

  def handle_event("org_remove_lock", _v, socket) do
    {
      :noreply,
      socket
      |> assign(:can_remove_org, not socket.assigns[:can_remove_org])
    }
  end

  def handle_event("org_save", %{"org" => org}, socket) do
    ch = socket.assigns[:change_org].data
    |> Org.changeset(org)

    # IO.inspect ch

    case Repo.insert_or_update(ch) do
      {:ok, _ch} ->
        {
          :noreply,
          socket
          |> assign(:change_org, nil)
          |> assign_org_list
        }
      {:error, ch} ->
        {
          :noreply,
          socket
          |> assign(:change_org, ch)
        }
    end
  end

  def assign_org_list(socket) do
    orgs = Org.list([:public_keys])
    socket
    |> assign(:orgs, orgs)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    {:ok,
     socket
     |> assign_org_list
     |> assign(:change_org, nil)
     |> assign(:can_remove_org, false)
    }
  end

  def session_expired(socket) do
    {:noreply, socket}
  end
end
