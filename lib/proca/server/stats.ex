defmodule Proca.Server.Stats do
  @moduledoc """
  Stores campaign and action page signature counts in following structure (under campaign state key):

  - map of campaign ids stores a following structure:
    - supporters - how many deduplicated supporters in total (including `extra_supporters`)
    - action - action counts grouped by action type
    - area - supporters grouped by area
    - org - supporters grouped by org name

  extra_supporters are not included in action counts, nor in area counts (we do not know where they belong).

  ## Process state structure:

  - `interval`: int - calculation interval in ms
  - `query_runs`: boolean - a flag saying calculation is running now and we shouldn't run new calculation
  - `campaign`: `campaign_id -> %Stats{}` (map)
  """
  defstruct supporters: 0, action: %{}, area: %{}, org: %{}

  use GenServer
  alias Proca.Server.Stats
  alias Proca.{Action, Supporter, ActionPage, Campaign}
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
    unless state.query_runs do
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
  # XXXX org_id
  def handle_cast(
        {:increment, campaign_id, org_id, action_type, area, new_supporter},
        state = %{campaign: campaign}
      ) do
    sup_incr = if(new_supporter, do: 1, else: 0)
    incr = &(&1 + 1)
    incr_for_new = &(&1 + sup_incr)

    campaign =
      Map.update(
        campaign,
        campaign_id,
        # initial state if this campaign stats do not exist at all
        %Stats{
          supporters: sup_incr,
          action: %{action_type => 1},
          area: if(not is_nil(area), do: %{area => sup_incr}, else: %{}),
          org: %{org_id => sup_incr}
        },
        fn %Stats{supporters: sup_ct, action: types_ct, area: area_sup, org: org_sup} ->
          action2 = Map.update(types_ct, action_type, 1, incr)

          area2 =
            if not is_nil(area) do
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
        end
      )

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

  @doc """
  Run the full calculation of stats
  """
  def calculate() do
    # Calculation of supporters:
    # We can have many supporters records for same fingerprint.
    # We want to use only last one per each campaign.
    # We use ORDER + SELECT DISTINCT() to make the DB select such last records
    # When we calculate areas for campaign, we also do this, so if someone signed from two areas, only last one
    # is counted (within scope of campaign)

    org_supporters =
      from(
        a in Action,
        join: s in Supporter,
        on: a.supporter_id == s.id,
        join: ap in ActionPage,
        on: a.action_page_id == ap.id,
        where: s.processing_status == :accepted and
              a.processing_status in [:accepted, :delivered] and
              s.dupe_rank == 0,
        group_by: [a.campaign_id, ap.org_id],
        select: {a.campaign_id, ap.org_id, count(s.fingerprint, :distinct)}
      )
      |> Repo.all(timeout: 60_000)

    # create data for all campaigns so we don't have missing key below
    campaign_ids = Repo.all(from(c in Campaign, select: c.id), timeout: 30_000)

    result_all =
      campaign_ids
      |> Enum.map(&{&1, 0})
      |> Enum.into(%{})

    result_orgs =
      campaign_ids
      |> Enum.map(&{&1, %{}})
      |> Enum.into(%{})

    # Aggregate per-org and total supporters
    {result_all, result_orgs} =
      for {campaign_id, org_id, count} <- org_supporters, reduce: {result_all, result_orgs} do
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
      |> Repo.all(timeout: 30_000)

    # warning : if org has only exras, they are not yet in the map
    {result_all, result_orgs} =
      for {campaign_id, org_id, count} <- extra, reduce: {result_all, result_orgs} do
        {all, org} ->
          {
            all |> Map.update(campaign_id, count, fn x -> x + count end),
            org
            |> Map.update(
              campaign_id,
              %{org_id => count},
              &Map.update(&1, org_id, count, fn x -> x + count end)
            )
          }
      end

    action_counts =
      from(a in Action,
        where: a.processing_status in [:accepted, :delivered] and not a.testing,
        group_by: [a.campaign_id, a.action_type],
        select: {a.campaign_id, a.action_type, count(a.id)}
      )
      |> Repo.all(timeout: 30_000)

    result_action =
      for {campaign_id, action_type, count} <- action_counts, reduce: %{} do
        acc ->
          Map.update(acc, campaign_id, %{action_type => count}, &Map.put(&1, action_type, count))
      end

    result =
      for {campaign_id, total_supporters} <- result_all, into: %{} do
        {campaign_id, %Stats{supporters: total_supporters}}
      end

    result =
      for {campaign_id, org_stat} <- result_orgs, reduce: result do
        acc -> Map.put(acc, campaign_id, %Stats{acc[campaign_id] | org: org_stat})
      end

    result =
      for {campaign_id, action_stat} <- result_action, reduce: result do
        acc ->
          Map.put(acc, campaign_id, %Stats{acc[campaign_id] | action: action_stat})
      end

    result
  end

  # Client side
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Get stats for this `campaign_id` from Stat process.
  """
  def stats(campaign_id) do
    GenServer.call(__MODULE__, {:stats, campaign_id})
  end

  @doc """
  Increment by one action count for particular `action_type` collected by org with `org_id`, in campaign with `campaign_id`.
  The `new_supporter` is true if `addActionContact` was used to create action + supporter, otherwise a supporter was re-used (`addAction`).
  """
  def increment(campaign_id, org_id, action_type, new_supporter) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, org_id, action_type, nil, new_supporter})
  end

  @doc """
  Same as increment/4 but provides `area`
  """
  def increment(campaign_id, org_id, action_type, area, new_supporter) do
    GenServer.cast(
      __MODULE__,
      {:increment, campaign_id, org_id, action_type, area, new_supporter}
    )
  end
end
