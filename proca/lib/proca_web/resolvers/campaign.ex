defmodule ProcaWeb.Resolvers.Campaign do
  @moduledoc """
  Resolvers for campaign queries in mutations
  """
  import Ecto.Query
  import Proca.Repo
  alias Proca.Auth
  alias Proca.{Campaign, ActionPage, Org, Confirm}
  alias ProcaWeb.Helper
  alias Ecto.Multi

  @preload_query [preload: [:org, :targets]]

  def list(%Org{} = org, params, _) do
    r =
      Campaign.select_by_org(org)
      |> Campaign.all(Enum.to_list(Map.get(params, :select, %{})) ++ @preload_query)

    {:ok, r}
  end

  def list(_, %{id: id}, _) do
    {
      :ok,
      Campaign.all([id: id] ++ @preload_query)
    }
  end

  def list(_, %{name: name}, _) do
    {
      :ok,
      Campaign.all([name: name] ++ @preload_query)
    }
  end

  def list(_, %{title: title}, _) do
    {
      :ok,
      Campaign.all([title_like: title] ++ @preload_query)
    }
  end

  def return_from_context(_, _, %{context: %{campaign: c}}) do
    {:ok, c}
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
       supporter_count_by_area:
         supporters_by_areas |> Enum.map(fn {area, ct} -> %{area: area, count: ct} end),
       supporter_count_by_org: supporter_count_by_org,
       action_count: at_cts |> Enum.map(fn {at, ct} -> %{action_type: at, count: ct} end)
     }}
  end

  def targets(campaign, _a, _c) do
    t = Proca.Target.all(campaign: campaign, preload: [:emails])

    {:ok, t}
  end

  def org_stats(%{supporter_count_by_org: org_st}, _, _) do
    org_ids = Map.keys(org_st)

    with_names =
      from(o in Org, where: o.id in ^org_ids, select: {o.id, o.name, o.title})
      |> all()
      |> Enum.map(fn {id, name, title} ->
        %{
          org: %{name: name, title: title},
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
     |> Enum.sum()}
  end

  def upsert(_, %{input: attrs}, %{context: %{org: org}}) do
    alias Ecto.Multi

    {pages, attrs} = Map.pop(attrs, :action_pages, [])

    upsert_all =
      Multi.new()
      |> Multi.insert_or_update(:campaign, Campaign.upsert(org, attrs))
      |> Multi.merge(fn %{campaign: campaign} ->
        pages
        |> Enum.with_index()
        |> Enum.reduce(Multi.new(), fn {page, idx}, multi ->
          Multi.insert_or_update(
            multi,
            {:action_page, idx},
            ActionPage.upsert(org, campaign, page)
          )
        end)
      end)

    result = transaction_and_notify(upsert_all, :upsert_campaign)

    case result do
      {:ok, %{campaign: campaign}} -> {:ok, campaign}
      {:error, invalid} -> {:error, Helper.format_errors(invalid)}
    end
  end

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

  def add(_, %{input: params}, %{context: %{org: org}}) do
    %Campaign{}
    |> Campaign.changeset(
      params
      |> Map.put(:org, org)
    )
    |> insert_and_notify()
  end

  def update(_, %{input: params}, %{context: %{campaign: campaign}}) do
    campaign
    |> Campaign.changeset(params)
    |> update_and_notify()
  end

  def delete(_, _, %{context: %{campaign: campaign}}) do
    res =
      Campaign.delete(campaign)
      |> transaction_and_notify(:delete_campaign)

    case res do
      {:ok, _deleted} -> {:ok, :success}
      e -> e
    end
  end

  def action_pages_for_auth(%Campaign{} = camp, _params, %{
        context: %{auth: auth = %Auth{staffer: staffer}}
      }) do
    if Proca.Permission.can?(auth, [:instance_owner]) do
      {
        :ok,
        ActionPage.all(campaign: camp)
      }
    else
      org = Org.one(id: staffer.org_id)

      {
        :ok,
        ActionPage.all(org: org)
      }
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

      _staffer ->
        all_partner_ids =
          from(
            ap in ActionPage,
            where: ap.campaign_id == ^c_id and ap.org_id != ^lead_id,
            select: ap.org_id,
            distinct: true
          )

        partnerships =
          from(o in Org,
            where: o.id in subquery(all_partner_ids)
          )
          |> all()
          |> Enum.map(fn o -> %{org: o, campaign: campaign} end)

        {:ok, partnerships}
    end
  end

  def partnership_action_pages(
        %{org: %Org{id: org_id}, campaign: %Campaign{id: campaign_id}},
        _,
        _
      ) do
    {:ok,
     from(a in ActionPage, where: a.org_id == ^org_id and a.campaign_id == ^campaign_id) |> all()}
  end

  def partnership_launch_requests(
        %{org: %Org{id: org_id}, campaign: %Campaign{id: campaign_id}},
        _,
        _
      ) do
    {
      :ok,
      from(c in Confirm,
        join: ap in ActionPage,
        on: c.object_id == ap.id,
        where:
          c.operation == :launch_page and c.subject_id == ^campaign_id and ap.org_id == ^org_id,
        preload: [:creator]
      )
      |> where([c], c.charges > 0)
      |> all()
    }
  end

  def partnership_requesters(%{org: %{id: org_id}, campaign: %{id: campaign_id}}, _, _) do
    {
      :ok,
      from(user in Proca.Users.User,
        join: c in Confirm,
        on: user.id == c.creator_id,
        join: ap in ActionPage,
        on: c.object_id == ap.id,
        where:
          c.operation == :launch_page and c.subject_id == ^campaign_id and ap.org_id == ^org_id,
        distinct: true
      )
      |> all()
    }
  end
end
