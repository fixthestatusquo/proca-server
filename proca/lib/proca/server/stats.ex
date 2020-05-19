defmodule Proca.Server.Stats do
  use GenServer
  alias Proca.Supporter
  alias Proca.Repo
  import Ecto.Query

  @impl true
  @doc """
  Stores campaign and action page signature counts in following structure (under campaign state key):
  - map of campaign ids stores 2 element tuple 
  - first element is count for whole campaign
  - second element is a key list mapping action page id to count for this action page
  - XXX later: add extra signatories from ActionPage
  - XXX later: add counts for other actions (convert count to keylist)
  """
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
  def handle_cast({:increment, campaign_id, action_page_id}, state = %{campaign: campaign}) do
    campaign = with {camp_ct, ap_lst} <- Map.get(campaign, campaign_id, {0, []}),
                    {action_page_id, ap_ct} <- List.keyfind(ap_lst, action_page_id, 0, {action_page_id, 0})
      do
      Map.put(campaign, campaign_id,
        {
          camp_ct + 1,
          List.keystore(ap_lst,
            action_page_id, 0,
            {action_page_id, ap_ct + 1})
        })

    end
    {:noreply, %{state | campaign: campaign}}
  end

  @impl true
  @doc """
  Get stats for campaign
  """
  def handle_call({:stats, c_id}, _f, stats = %{campaign: camp}) do
    {cct, _apcs} = Map.get(camp, c_id, {0, nil})

    {:reply, cct, stats}
  end

  @impl true
  @doc """
  Get stats for action page
  """
  def handle_call({:stats, c_id, ap_id}, _f, stats = %{campaign: camp}) do
    with {_all, aps} <- Map.get(camp, c_id, {0, []}),
         {_ap_id, apct} = List.keyfind(aps, ap_id, 0, {ap_id, 0})
      do
      {:reply, apct, stats}
    end
  end

  def calculate() do
    query = from(s in Supporter, order_by: s.inserted_at)
    |> distinct([s], s.fingerprint)
    |> subquery()
    |> group_by([s], [s.campaign_id, s.action_page_id])
    |> select([s], [s.campaign_id, s.action_page_id, count(s.fingerprint)])

    query
    |> Repo.all()
    |> Enum.reduce(%{}, &row_to_state/2)
  end

  defp row_to_state([c_id, ap_id, sig_ct], acc) do
    {camp_sum, ap_lst} = Map.get(acc, c_id, {0, []})

    Map.put(acc, c_id, {
          camp_sum + sig_ct,
          [{ap_id, sig_ct} | ap_lst]
            })
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

  def increment(campaign_id, action_page_id) do
    GenServer.cast(__MODULE__, {:increment, campaign_id, action_page_id})
  end
end
