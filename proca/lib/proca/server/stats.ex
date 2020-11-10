defmodule Proca.Server.Stats do
  @moduledoc """
  Stores campaign and action page signature counts in following structure (under campaign state key):
  - map of campaign ids stores 2 element tuple 
  - first element is count for whole campaign
  - second element is a key list mapping action page id to count for this action page
  - XXX later: add extra signatories from ActionPage
  - XXX later: add counts for other actions (convert count to keylist)

  ## State structure:

  interval: int - calculation interval in ms
  query_runs: boolean - a flag saying calculation is running now and we shouldn't run new calculation
  campaign:
  campaign_id ->  (map)
  {deduped supporters, [action_type: count]}
  """

  use GenServer
  alias Proca.{Action, Supporter, ActionPage}
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
  def handle_cast(
        {:increment, campaign_id, action_type, new_supporter},
        state = %{campaign: campaign}
      ) do
    campaign =
      with {sup_ct, types_ct} <- Map.get(campaign, campaign_id, {0, []}),
           {action_type, at_ct} <- List.keyfind(types_ct, action_type, 0, {action_type, 0}) do
        Map.put(campaign, campaign_id, {
          sup_ct + if(new_supporter, do: 1, else: 0),
          List.keystore(types_ct, action_type, 0, {action_type, at_ct + 1})
        })
      end

    {:noreply, %{state | campaign: campaign}}
  end

  @impl true
  @doc """
  - Get stats for campaign
  - Get stats for action types
  """
  def handle_call({:stats, c_id}, _f, stats = %{campaign: camp}) do
    cst = Map.get(camp, c_id, {0, []})

    {:reply, cst, stats}
  end

  @impl true
  def handle_call({:stats, c_id, types}, _f, stats = %{campaign: camp}) do
    with {sup, types_ct} <- Map.get(camp, c_id, {0, []}),
         counts <- Enum.map(types, fn t -> List.keyfind(types_ct, t, 0, {t, 0}) end) do
      {:reply, {sup, counts}, stats}
    end
  end

  def calculate() do
    query =
      from(s in Supporter, order_by: s.inserted_at)
      |> distinct([s], s.fingerprint)
      |> subquery()
      |> group_by([s], [s.campaign_id])
      |> select([s], [s.campaign_id, count(s.fingerprint)])

    supporters =
      query
      |> Repo.all()
      |> Enum.reduce(%{}, fn [c_id, sup_ct], acc -> Map.put(acc, c_id, {sup_ct, []}) end)

    extra_supporters =
      from(ap in ActionPage,
        group_by: ap.campaign_id,
        where: ap.extra_supporters != 0,
        select: [ap.campaign_id, sum(ap.extra_supporters)]
      )
      |> Repo.all()
      |> Enum.reduce(%{}, fn [c_id, ex_ct], acc -> Map.put(acc, c_id, {ex_ct, []}) end)

    # merge supporters and extra_supporters

    action_counts =
      from(a in Action,
        group_by: [a.campaign_id, a.action_type],
        select: [a.campaign_id, a.action_type, count(a.id)]
      )
      |> Repo.all()
      |> Enum.reduce(%{}, &add_action_type_counts/2)

    supporters
    |> Map.merge(extra_supporters, fn _c_id, {su, []}, {ex, []} -> {su + ex, []} end)
    |> Map.merge(action_counts, fn _c_id, {su, []}, {_x, ats} -> {su, ats} end)
  end

  defp add_action_type_counts([c_id, at, ct], acc) do
    {_sc, ats} = Map.get(acc, c_id, {0, []})
    Map.put(acc, c_id, {0, List.keystore(ats, at, 0, {at, ct})})
  end

  # Client side
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def stats(campaign_id) do
    GenServer.call(__MODULE__, {:stats, campaign_id})
  end

  def stats(campaign_id, action_page_id) do
    GenServer.call(__MODULE__, {:stats, campaign_id, action_page_id})
  end

  def increment(campaign_id, action_type, new_supporter) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, action_type, new_supporter})
  end
end
