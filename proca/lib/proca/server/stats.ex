defmodule Proca.Server.Stats do
  @moduledoc """
  Stores campaign and action page signature counts in following structure (under campaign state key):
  - map of campaign ids stores 2 element tuple 
  - first element is count for whole campaign
  - second element is a keylist mapping action_type to count

  extra_supporters are included in supoorters count

  TODO: how to add extra_supporters to areas?

  ## State structure:

  interval: int - calculation interval in ms
  query_runs: boolean - a flag saying calculation is running now and we shouldn't run new calculation
  campaign:
  campaign_id ->  (map)
  {deduped supporters, %{action_type: count}, %{area: count}, %{org_id: count}}
  """
  defstruct supporters: 0, action: %{}, area: %{}, org: %{}

  use GenServer
  alias Proca.Server.Stats
  alias Proca.{Action, Supporter, ActionPage, Contact}
  alias Proca.Repo
  import Ecto.Query

  @impl true
  def init(sync_every_ms) do
    {
      :ok,
      %{
        interval: sync_every_ms,
        campaign: %{},
        query_runs: false
      },
      {:continue, :first_load}
    }
  end

  # Sync counts from DB on every interval

  @impl true
  def handle_continue(:first_load, state) do
    handle_info(:sync, state)
  end

  @impl true
  @doc """
  Every @sync_every_ms ms we send to ourselves a :sync message, to synchronize counts from DB.
  """
  def handle_info(:sync, state) do
    if not state.query_runs do
      me = self()
      Task.start_link(fn -> GenServer.cast(me, {:update_campaigns, calculate()}) end)
    end

    if state.interval > 0 do
      Process.send_after(self(), :sync, state.interval)
    end

    {:noreply, %{state | query_runs: true}}
  end

  # Update state from DB or from increment

  @impl true
  def handle_cast({:update_campaigns, campaign}, state) do
    {:noreply, %{state | campaign: campaign, query_runs: false}}
  end

  @impl true 
  def handle_cast(    # XXXX org_id
        {:increment, campaign_id, org_id, action_type, area, new_supporter},
        state = %{campaign: campaign}
      ) do

    sup_incr = if(new_supporter, do: 1, else: 0)
    incr = &(&1 + 1)
    incr_for_new = &(&1 + sup_incr)

    campaign = Map.update(campaign, campaign_id, 
    # initial state if this campaign stats do not exist at all
    %Stats{
      supporters: sup_incr,
      action: %{ action_type => 1},
      area: if(not is_nil(area), do: %{ area => sup_incr }, else: %{}),
      org: %{ org_id => sup_incr }
      },
      fn %Stats{supporters: sup_ct, 
      action: types_ct, 
      area: area_sup,
      org: org_sup
      } -> 

        action2 = Map.update(types_ct, action_type, 1, incr)

        area2 = if not is_nil(area) do 
          Map.update(area_sup, area, 1, incr_for_new)
        else
          area_sup
        end

        org2 = Map.update(org_sup, org_id, sup_incr, incr_for_new)
        sup2 = incr_for_new.(sup_ct)

        %Stats{
          supporters: sup2,
          action: action2,
          area: area2, 
          org: org2
        }
      end)


    {:noreply, %{state | campaign: campaign}}
  end

  @impl true
  @doc """
  - Get stats for campaign
  - Get stats for action types
  """
  def handle_call({:stats, c_id}, _f, stats = %{campaign: camp}) do
    cst = Map.get(camp, c_id, %Stats{})

    {:reply, cst, stats}
  end

  def calculate() do
    # Calculation of supporters:
    # We can have many supporters records for same fingerprint.
    # We want to use only last one per each campaign.
    # We use ORDER + SELECT DISTINCT() to make the DB select such last records
    # When we calculate areas for campaign, we also do this, so if someone signed from two areas, only last one 
    # is counted (within scope of campaign)

    first_supporter_query = 
      from(a in Action, join: s in Supporter,  on: a.supporter_id == s.id, order_by: a.inserted_at)
      |> where([a, s], s.processing_status in [:accepted, :delivered] and a.processing_status in [:accepted, :delivered])
      |> distinct([a, s], [a.campaign_id, s.fingerprint])

    first_supporter_query
    |> Repo.all() 

#     all_supporters_query = 
#       first_supporter_query
#       |> subquery()
#       |> group_by([s], [s.campaign_id])
#       |> select([s], [s.campaign_id, count(s.fingerprint)]) # group by org?
# 
#     supporters =
#       all_supporters_query
#       |> Repo.all()
#       |> Enum.reduce(%{}, fn [c_id, sup_ct], acc -> Map.put(acc, c_id, {sup_ct, [], %{}}) end)
# 
    org_supporters_query = 
      first_supporter_query
      |> subquery()
      |> join(:inner, [a], s in Supporter, on: s.id == a.supporter_id)
      |> join(:inner, [a, s], p in Contact, on: p.supporter_id == s.id)
      |> group_by([a, s, p], [a.campaign_id, p.org_id])
      |> select([a, s, p], {a.campaign_id, p.org_id, count(s.fingerprint)})

    org_supporters = 
      org_supporters_query
      |> Repo.all()

    # Aggregate per-org and total supporters 
    {result_all, result_orgs} =
    for {campaign_id, org_id, count} <- org_supporters, reduce: {%{}, %{}} do 
      # go through rows and aggregate on two levels
      {all_sup, org_sup} -> 
        {
          # per campaign_id
          Map.update(all_sup, campaign_id, count, &(&1 + count)),
          # nested map campaign_id -> org_id
          Map.update(org_sup, campaign_id, %{org_id => count}, &Map.put(&1, org_id, count))
        }
    end

    # Add extra suppoters - to per org and to total
    extra = 
      from(ap in ActionPage,
        group_by: [ap.campaign_id, ap.org_id],
        where: ap.extra_supporters != 0,
        select: {ap.campaign_id, ap.org_id, sum(ap.extra_supporters)}
      )
      |> Repo.all()


    # warning : if org has only exras, they are not yet in the map
    {result_all, result_orgs} = 
    for {campaign_id, org_id, count} <- extra, reduce: {result_all, result_orgs} do 
      {all, org} ->
      {
        all |> Map.update(campaign_id, count, fn x -> x + count end),
        org |> Map.update(campaign_id, %{org_id => count}, &Map.update(&1, org_id, count, fn x -> x + count end))
      }
    end

    # count supporters per area (extra supporters do not apply here); we might add default area to 
    # action page and then we could add them here.. - would need a campaign,area -> extra aggregate
    area_supporters_query = 
      first_supporter_query
      |> where([a, s], not is_nil(s.area))
      |> subquery()
      |> join(:inner, [a], s in Supporter, on: s.id == a.supporter_id)
      |> group_by([a, s], [a.campaign_id, s.area])
      |> select([a, s], {a.campaign_id, s.area, count(s.fingerprint)})

    area_supporters =
      area_supporters_query
      |> Repo.all()

    result_area = 
      for {campaign_id, area, count} <- area_supporters, reduce: %{} do 
        area_sup -> 
          Map.update(area_sup, campaign_id, %{area => count}, &Map.put(&1, area, count))
      end


    action_counts =
      from(a in Action,
        where: a.processing_status in [:accepted, :delivered],
        group_by: [a.campaign_id, a.action_type],
        select: {a.campaign_id, a.action_type, count(a.id)}
      )
      |> Repo.all()

    result_action = 
      for {campaign_id, action_type, count} <- action_counts, reduce: %{} do 
        acc -> 
            Map.update(acc, campaign_id, %{action_type => count}, &Map.put(&1, action_type, count))
      end

    result = 
      for {campaign_id, total_supporters} <- result_all, into: %{} do 
        {campaign_id, %Stats{supporters: total_supporters  }}
      end

    result =
      for {campaign_id, org_stat} <- result_orgs, reduce: result do 
        acc -> Map.put(acc, campaign_id,  %Stats{acc[campaign_id] | org: org_stat})
      end

    result =
      for {campaign_id, area_stat} <- result_area, reduce: result do 
        acc -> Map.put(acc, campaign_id,  %Stats{acc[campaign_id] | area: area_stat})
      end
  
    result =
      for {campaign_id, action_stat} <- result_action, reduce: result do 
        acc -> 
        Map.put(acc, campaign_id,  %Stats{acc[campaign_id] | action: action_stat})
      end

    result
  end


  # Client side
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def stats(campaign_id) do
    GenServer.call(__MODULE__, {:stats, campaign_id})
  end

  def increment(campaign_id, org_id, action_type, new_supporter) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, org_id, action_type, nil, new_supporter})
  end

  def increment(campaign_id, org_id, action_type, area, new_supporter) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, org_id, action_type, area, new_supporter})
  end

end
