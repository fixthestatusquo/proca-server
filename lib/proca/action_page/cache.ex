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

  The cache is a lazy, process-independent ETS table (`:public`), mirroring the
  pattern used by `Proca.Server.MTTContext` and `Proca.Service.EmailBudget`, so
  it needs no supervision wiring.
  """
  @table __MODULE__
  @default_ttl_ms :timer.minutes(5)

  defp ensure_table do
    case :ets.whereis(@table) do
      :undefined -> :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
      _ -> @table
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
    :ets.delete(@table, action_page_ids)
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
