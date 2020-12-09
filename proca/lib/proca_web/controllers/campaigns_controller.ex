defmodule ProcaWeb.CampaignsController do
  use ProcaWeb, :live_view
  alias Proca.{Org, Campaign, ActionPage}
  alias Proca.Repo
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Server.Notify

  def handle_event("campaign_new", _value, socket) do
    {
      :noreply,
      socket
      |> assign(:campaign, Campaign.changeset(%Campaign{}, %{}))
    }
  end

  def handle_event("action_page_new", %{"campaign_id" => campaign_id}, socket) do
    ch =
      ActionPage.changeset(%{})
      |> put_change(:org_id, socket.assigns[:staffer].org_id)

    {
      :noreply,
      socket
      |> assign(:action_page, ch)
      |> assign_selected_campaign(campaign_id)
      |> assign_partners
    }
  end

  def handle_event("action_page_edit", %{"id" => ap_id}, socket) do
    ap =  ActionPage.find(String.to_integer(ap_id))
    {
      :noreply,
      socket
      |> assign(:action_page, ActionPage.changeset(ap, %{}))
      |> assign_selected_campaign(ap.campaign_id)
      |> assign_partners
    }
  end

  def handle_event("action_page_save", %{"action_page" => attrs}, socket) do
    ch = socket.assigns[:action_page]

    org_id =
      case Map.get(attrs, "org_id", nil) do
        nil -> socket.assigns[:staffer].org_id
        o -> String.to_integer(o)
      end

    new_ch =
      ch.data
      |> ActionPage.changeset(attrs)
      |> put_change(:org_id, org_id)
      |> put_assoc(:campaign, socket.assigns[:selected_campaign])

    case Repo.insert_or_update(new_ch) do
      {:ok, ap} ->
        Notify.action_page_updated(ap)

        {
          :noreply,
          socket
          |> assign(:action_page, nil)
          |> assign_campaigns
        }

      {:error, bad_ch} ->
        {
          :noreply,
          socket |> assign(:action_page, bad_ch)
        }
    end
  end

  def handle_event("action_page_remove", %{"id" => id}, socket) do
    org_id = socket.assigns[:staffer].org_id

    from(ap in ActionPage, where: ap.id == ^id and ap.org_id == ^org_id)
    |> Repo.delete_all()
  end

  def handle_event("campaign_edit", %{"campaign_id" => cid}, socket) do
    {
      :noreply,
      socket
      |> assign(:campaign, Campaign.changeset(Repo.get(Campaign, cid), %{}))
    }
  end

  def handle_event("modal_discard", %{"modal" => modal}, socket) do
    s2 =
      case modal do
        "campaign" -> assign(socket, :campaign, nil)
        "action_page" -> assign(socket, :action_page, nil)
      end

    {:noreply, s2}
  end

  def handle_event("campaign_remove", %{"id" => cid}, socket) do
    c = Repo.get(Campaign, cid)
    {:ok, _c} = Repo.delete(c)

    {:noreply,
     socket
     |> assign(:campaign, nil)
     |> assign_campaigns}
  end

  def handle_event("campaign_save", %{"campaign" => campaign}, socket) do
    case socket.assigns[:campaign].data
    |> Campaign.changeset(campaign)
    |> put_change(:org_id, socket.assigns[:staffer].org.id)
    |> put_change(:public_actions, public_actions_for(campaign))
    |> Repo.insert_or_update() do
      {:ok, _c} ->
        {
          :noreply,
          socket
          |> assign(:campaign, nil)
          |> assign_campaigns
        }

      {:error, ch} ->
        {
          :noreply,
          socket
          |> assign(:campaign, ch)
        }
    end
  end

  def public_actions_for(campaign) do
    %{
      "public_petition_comments" => ["petition:comment"],
      "public_openletter" => [
        "openletter:twitter",
        "openletter:comment",
        "openletter:organisation",
        "openletter:picture"
      ]
    }
    |> Enum.reduce([], fn {checkbox, pub_act}, whitelist ->
      if campaign[checkbox] == "true" do
        pub_act ++ whitelist
      else
        whitelist
      end
    end)
  end


  def render(assigns) do
    Phoenix.View.render(ProcaWeb.DashView, "campaigns.html", assigns)
  end

  def mount(_params, session, socket) do
    socket = mount_user(socket, session)

    if socket.redirected do
      {:ok, socket}
    else
      {:ok,
       socket
       |> assign_campaigns
       |> assign(:campaign, nil)
       |> assign(:action_page, nil)
       |> assign(:partners, nil)}
    end
  end

  def assign_campaigns(socket) do
    org_id = socket.assigns[:staffer].org_id

    cs =
      from(c in Campaign,
        where: c.org_id == ^org_id,
        preload: [:org, action_pages: :org],
        order_by: [desc: c.inserted_at]
      )
      |> Repo.all()

    partner_cs =
      from(c in Campaign,
        join: ap in ActionPage,
        on: c.id == ap.campaign_id,
        where: c.org_id != ^org_id and ap.org_id == ^org_id,
        preload: [:org, action_pages: :org],
        order_by: [desc: c.inserted_at],
        distinct: true
      )
      |> Repo.all()
      |> Enum.map(fn c ->
        case c.org_id do
          ^org_id -> c
          _ -> %{c | action_pages: Enum.filter(c.action_pages, fn ap -> ap.org_id == org_id end)}
        end
      end)

    socket
    |> assign(:campaigns, cs ++ partner_cs)
  end

  def assign_partners(socket) do
    partners = Org.list() |> Enum.map(fn o -> {o.name, o.id} end)
    assign(socket, :partners, partners)
  end

  def assign_selected_campaign(socket, campaign_id) when is_bitstring(campaign_id) do
    assign_selected_campaign(socket, String.to_integer(campaign_id))
  end

  def assign_selected_campaign(socket, campaign_id) when is_integer(campaign_id) do
    socket
    |> assign(
      :selected_campaign,
      Enum.find(
        socket.assigns[:campaigns],
        fn c -> c.id == campaign_id end
      )
    )
  end

  def session_expired(socket) do
    {:noreply, socket}
  end
end
