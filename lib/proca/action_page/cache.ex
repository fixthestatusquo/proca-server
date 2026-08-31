defmodule Proca.ActionPage.Cache do
  @moduledoc """
  Small TTL cache for preloaded `ActionPage` records.

  The action resolver re-reads an action page (plus all its preloads: org,
  campaign, campaign.org, campaign.mtt) on every single request. For bursts of
  signatures targeting the *same* page this is many identical, effectively
  immutable reads per request. This cache stores the fully preloaded record
  keyed by `action_page_id` for a short TTL so those reads are skipped.

  Correctness is preserved by:

  - the short TTL (bounded staleness — admin edits surface within a minute),
  - explicit invalidation (`bust/1`, `bust/2`, `clear/0`) hooked into the
    ordinary update notifications in `Proca.Server.Notify`.

  ## Concurrency

  The cache is a supervised `GenServer` that creates its (single) `:public` ETS
  table once at application boot, before any request can arrive. This avoids the
  create-once table race that a lazy `:ets.whereis` + `:ets.new` pattern has
  under concurrent load. Because the table is `:public`, reads/writes happen
  directly in the caller process with no GenServer round-trip, keeping the hot
  path fast. `ensure_table/0` remains as a race-tolerant fallback for direct
  calls made before/without boot (e.g. tests), rescuing the "table already
  exists" `ArgumentError` instead of crashing.
  """
  use GenServer

  @table __MODULE__
  @default_ttl_ms :timer.minutes(5)

  # Bounds the table so it cannot grow without limit (guards against running
  # many distinct action pages through the cache). When exceeded, the table is
  # cleared; pages are cheap to re-fetch on a subsequent miss.
  @max_cache_entries 100_000

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    # Public: any process reads/writes the ETS table directly for low latency.
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, %{}}
  end

  # Race-tolerant table creation. At boot the supervised child creates the table
  # once, so in production this is normally a no-op returning the existing table.
  # The rescue handles the (now unlikely) case where two callers race a lazy
  # creation (e.g. tests that never booted the supervisor): the winner creates
  # the table and the loser simply reuses it instead of crashing.
  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined ->
        try do
          :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
        rescue
          ArgumentError -> @table
        end

      _table ->
        @table
    end
  end

  @doc """
  Look up a cached value for `action_page_id`.

  Returns `{:hit, value}` when a live entry exists, otherwise `:miss`. Expired
  entries are evicted on read.
  """
  def lookup(action_page_id) when is_integer(action_page_id) do
    ensure_table()
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@table, action_page_id) do
      [{^action_page_id, value, expires_at}] when expires_at > now ->
        {:hit, value}

      [{^action_page_id, _value, _expires_at}] ->
        :ets.delete(@table, action_page_id)
        :miss

      [] ->
        :miss
    end
  end

  @doc """
  Store `value` for `action_page_id`, expiring after `ttl_ms` (default TTL).
  """
  def put(action_page_id, value, ttl_ms \\ @default_ttl_ms) when is_integer(action_page_id) do
    ensure_table()

    if :ets.info(@table, :size) >= @max_cache_entries do
      :ets.delete_all_objects(@table)
    end

    expires_at = System.monotonic_time(:millisecond) + ttl_ms
    :ets.insert(@table, {action_page_id, value, expires_at})
    value
  end

  @doc """
  Remove an entry (or a list of entries) from the cache.
  """
  def bust(action_page_id) when is_integer(action_page_id) do
    ensure_table()
    :ets.delete(@table, action_page_id)
    :ok
  end

  def bust(action_page_ids) when is_list(action_page_ids) do
    ensure_table()
    Enum.each(action_page_ids, &:ets.delete(@table, &1))
    :ok
  end

  @doc """
  Remove all entries. Used when a campaign or org changes, since those edits can
  affect every cached page under them and there is no cheap id-based lookup.
  """
  def clear do
    ensure_table()
    :ets.delete_all_objects(@table)
    :ok
  end
end
