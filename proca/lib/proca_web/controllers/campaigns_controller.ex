defmodule ProcaWeb.CampaignsController do
  use Phoenix.LiveView
  use ProcaWeb.Live.AuthHelper, otp_app: :proca
  alias Proca.{Org,Staffer,Campaign,ActionPage}
  alias Proca.Users.User
  alias Proca.Repo
  import Ecto.Query
  import Ecto.Changeset


  def handle_event("campaign_new", _value, socket) do
    {
      :noreply,
      socket
      |> assign(:campaign, Campaign.changeset(%Campaign{}, %{}))
    }
  end

  def handle_event("campaign_edit", %{"campaign_id" => cid}, socket) do
    {
      :noreply,
      socket
      |> assign(:campaign, Campaign.changeset(Repo.get(Campaign, cid), %{}))
    }
  end

  def handle_event("campaign_discard", _value, socket) do
    {:noreply,
     socket
     |> assign(:campaign, nil)
    }
  end

  def handle_event("campaign_remove", %{"id" => cid}, socket) do
    c = Repo.get(Campaign, cid)
    {:ok, _c} = Repo.delete(c)

    {:noreply,
     socket
     |> assign(:campaign, nil)
     |> assign_campaigns
    }
  end

  def handle_event("campaign_save", %{"campaign" => campaign}, socket) do
    case socket.assigns[:campaign].data
    |> Campaign.changeset(campaign)
    |> put_change(:org_id, socket.assigns[:staffer].org.id)
    |> Repo.insert_or_update
      do
      {:ok, c} ->
        IO.inspect(c, label: "campaign_saved")
        {
          :noreply,
          socket
          |> assign(:campaign, nil)
          |> assign_campaigns
        }
      {:error, ch} ->
        IO.inspect(ch, label: "campaign_save")
        {
          :noreply,
          socket
          |> assign(:campaign, ch)
        }
    end
  end

  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "campaigns.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    {:ok,
     socket
     |> assign_campaigns
     |> assign(:campaign, nil)
    }
  end

  def assign_campaigns(socket) do
    org_id = socket.assigns[:staffer].org_id
    cs = from(c in Campaign,
      where: c.org_id == ^org_id,
      preload: [:action_pages],
      order_by: [desc: c.inserted_at])
    |> Repo.all

    socket
    |> assign(:campaigns, cs)
  end

  def session_expired(socket) do
    {:noreply, socket}
  end
end
