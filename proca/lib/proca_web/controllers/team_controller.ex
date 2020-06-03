defmodule ProcaWeb.TeamController do
  use ProcaWeb, :live_view
  alias Proca.{Org, Staffer}
  alias Proca.Staffer.Role
  alias Proca.Users.User
  alias Proca.Repo
  alias Ecto.Changeset
  import Ecto.Query

  def handle_event("change_role", %{"staffer" => staffer_id_str, "role" => role}, socket) do
    with %Staffer{} = staffer <- Repo.get(Staffer, staffer_id_str |> String.to_integer()),
         change_role <- Role.change(staffer, Role.from_string(role)) do
      {:ok, _} = Repo.update(change_role)

      {
        :noreply,
        socket
        |> assign_staffers(socket.assigns[:staffer].org_id)
      }
    end
  end

  def handle_event("show_invite", _, socket) do
    org_id = socket.assigns[:staffer].org_id

    {
      :noreply,
      socket
      |> assign(:invitable_users, Staffer.not_in_org(org_id))
    }
  end

  def handle_event("invite", %{"user" => user_id_str}, socket) do
    org_id = socket.assigns[:staffer].org_id
    user_id = user_id_str |> String.to_integer()

    {:ok, _staffer} =
      Repo.insert(
        Staffer.changeset(
          %Staffer{},
          %{
            user_id: user_id,
            org_id: org_id,
            perms: 0
          }
        )
      )

    {
      :noreply,
      socket
      |> assign(:invitable_users, nil)
      |> assign_staffers(socket.assigns[:staffer].org_id)
    }
  end

  def handle_event("remove_staffer", %{"staffer" => staffer_id_str}, socket) do
    with %Staffer{} = staffer <- Repo.get(Staffer, staffer_id_str |> String.to_integer()) do
      {:ok, _removed} = Repo.delete(staffer)

      {
        :noreply,
        socket
        |> assign_staffers(socket.assigns[:staffer].org_id)
      }
    end
  end

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "team.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    if socket.redirected do
      {:ok, socket}
    else
      {:ok,
       socket
       |> assign_staffers(socket.assigns[:staffer].org_id)}
    end
  end

  def assign_staffers(socket, org_id) do
    staffers =
      Staffer.get_by_org(org_id, [:user])
      |> Enum.sort_by(& &1.user.email)

    socket
    |> assign(:staffers, staffers)
    |> assign(:roles, roles())
    |> assign(:team_roles, team_roles(staffers))
    |> assign(:invitable_users, nil)
  end

  def session_expired(socket) do
    {:noreply, socket}
  end

  def roles() do
    [
      :campaign_manager,
      :campaigner,
      :mechanic,
      :robot
    ]
  end

  def team_roles(staffers) do
    staffers
    |> Enum.reduce(%{}, fn st, acc ->
      Map.put(acc, st.id, Role.findrole(st, roles()))
    end)
    |> IO.inspect(label: "team_roles")
  end
end
