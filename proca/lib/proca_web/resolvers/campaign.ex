defmodule ProcaWeb.Resolvers.Campaign do
  @moduledoc """
  Resolvers for campaign queries in mutations
  """
  import Ecto.Query
  import Proca.Repo
  alias Proca.{Campaign, ActionPage, Staffer, Org, Confirm}
  import Proca.Staffer.Permission
  alias ProcaWeb.Helper

  def list(_, %{id: id}, _) do
    cl =
      list_query()
      |> where([x], x.id == ^id)
      |> all()

    {:ok, cl}
  end

  def list(_, %{name: name}, _) do
    cl =
      list_query()
      |> where([x], x.name == ^name)
      |> all()

    {:ok, cl}
  end

  def list(_, %{title: title}, _) do
    cl =
      list_query()
      |> where([x], like(x.title, ^title))
      |> all()

    {:ok, cl}
  end

  def list(_, _, _) do
    cl = all(list_query())
    {:ok, cl}
  end

  defp list_query() do
    from(x in Proca.Campaign, preload: [:org])
  end

  def stats(campaign, _a, _c) do
    %Proca.Server.Stats{
      supporters: supporters, 
      action: at_cts, 
      area: supporters_by_areas,
      org: supporter_count_by_org
      } = Proca.Server.Stats.stats(campaign.id)

    {:ok,
     %{
       supporter_count: supporters,
       supporter_count_by_area: supporters_by_areas |> Enum.map(fn {area, ct} -> %{area: area, count: ct} end),
       supporter_count_by_org: supporter_count_by_org,
       action_count: at_cts |> Enum.map(fn {at, ct} -> %{action_type: at, count: ct} end),
     }}
  end

  def org_stats(%{supporter_count_by_org: org_st}, _, _) do 
    org_ids = Map.keys(org_st)

    with_names = 
    from(o in Org, where: o.id in ^org_ids, select: {o.id, o.name, o.title})
    |> all()
    |> Enum.map(fn {id, name, title} -> 
      %{
        org: %{ name: name, title: title },
        count: org_st[id]
      }
    end)

    {:ok, with_names}
  end

  def org_stats_others(par, %{org_name: org_name}, ctx) do 
    {:ok, by_names} = org_stats(par, %{}, ctx)

    {:ok, 
      by_names 
      |> Enum.filter(fn %{org: %{name: name}} -> name != org_name end)
      |> Enum.map(fn %{count: count} -> count end)
      |> Enum.sum()
    }
  end 

  @doc "XXX deprecated in favor of upsert/3"
  def declare_upsert(p, attrs, res) do
    upsert(p, %{input: attrs}, res)
  end

  def upsert(_, %{input: attrs = %{action_pages: pages}}, %{context: %{org: org}}) do
    # XXX Add name: attributes if url given (Legacy for declare_campaign)
    pages =
      Enum.map(pages, fn ap ->
        case ap do
          %{url: url} -> Map.put(ap, :name, url)
          ap -> ap
        end
      end)

    result = transaction(fn ->
      campaign = upsert_campaign(org, attrs)
      pages
      |> Enum.map(&fix_page_legacy_url/1)
      |> Enum.each(fn page ->
        ap = upsert_action_page(org, campaign, page)
        Proca.Server.Notify.action_page_updated(ap)
        ap
      end)

      campaign
    end)

    case result do
      {:ok, _} = r -> r
      {:error, invalid} -> {:error, Helper.format_errors(invalid)}
    end
  end

  # XXX for declareCampaign support
  defp fix_page_legacy_url(page = %{url: url}) do
    case url do
      "https://" <> n -> %{page | name: n}
      "http://" <> n -> %{page | name: n}
      n -> %{page | name: n}
    end
    |> Map.delete(:url)
  end

  defp fix_page_legacy_url(page), do: page

  def upsert_campaign(org, attrs) do
    campaign = Campaign.upsert(org, attrs)

    if not campaign.valid? do
      rollback(campaign)
    end

    if campaign.data.id do
      update!(campaign)
    else
      insert!(campaign)
    end
  end

  def upsert_action_page(org, campaign, attrs) do
    ap = ActionPage.upsert(org, campaign, attrs)

    if not ap.valid? do
      rollback(ap)
    end

    if ap.data.id do
      update!(ap)
    else
      insert!(ap)
    end
  end

  @doc """
  We do not have a partnership object yet but lets simulate it by getting all partner orgs with ap in that campaign
  """
  def partnerships(%Campaign{id: c_id, org_id: lead_id} = campaign, _, %{context: %{user: user}}) do 
    # XXX create visible_for helper which calls a fn ?
    case Proca.Staffer.for_user_in_org(user, lead_id) do 
      nil -> 
        {:ok, nil}
      staffer -> 
        all_partner_ids = from(
          ap in ActionPage, 
          where: ap.campaign_id == ^c_id and ap.org_id != ^lead_id, 
          select: ap.org_id, 
          distinct: true
        )
        partnerships = from(o in Org, 
          where: o.id in subquery(all_partner_ids)
        )
        |> all()
        |> Enum.map(fn o -> %{org: o, campaign: campaign} end)
        {:ok, partnerships}
    end
  end

  def partnership_action_pages(%{org: %Org{id: org_id}, campaign: %Campaign{id: campaign_id}}, _, _) do 
    {:ok, 
      from(a in ActionPage, where: a.org_id == ^org_id and a.campaign_id == ^campaign_id) |> all()
    }
  end



  def partnership_launch_requests(%{org: %Org{id: _org_id}, campaign: %Campaign{id: campaign_id}}, _, _) do 
    {
      :ok, 
      from(c in Confirm, where: c.operation == :launch_page and c.subject_id == ^campaign_id) 
      |> where([c], c.charges > 0)
      |> all()
    }
  end

end
