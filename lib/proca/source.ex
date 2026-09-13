defmodule Proca.Source do
  @moduledoc """
  Holds utm codes. Will be reused by many actions
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Proca.Changeset
  alias Proca.Repo
  alias Proca.Source

  @cache_table __MODULE__.Cache
  @registry Proca.Source.Lock

  # Fixed TTL. Sources are append-only and never deleted, so TTL only bounds
  # memory, not correctness. 5 min keeps a hot source alive between misses
  # without re-fetching it every few seconds.
  @cache_ttl_ms :timer.minutes(5)

  # Hard size cap: bounds memory against a flood of distinct sources.
  @max_cache_entries 100_000

  # Single-flight follower wait budget. The leader is a long-lived request
  # process, so followers poll the cache for the result rather than monitor the
  # leader for :DOWN.
  @lock_wait_timeout_ms 5_000
  @poll_interval_ms 10

  schema "sources" do
    field :campaign, :string, default: "unknown"
    field :content, :string, default: ""
    field :medium, :string, default: "unknown"
    field :source, :string, default: "unknown"
    field :location, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:source, :medium, :campaign, :content, :location])
    |> validate_required([:source, :medium, :campaign])
  end

  def build_from_attrs(attrs) do
    attrs =
      attrs
      |> default_location()

    %Source{}
    |> cast(attrs, [:source, :medium, :campaign, :content, :location])
    |> validate_required([:source, :medium, :campaign])
    |> trim(:source, 255)
    |> trim(:medium, 255)
    |> trim(:campaign, 255)
    |> trim(:content, 255)
    |> trim(:location, 255)
  end

  def default_location(attrs = %{location: nil}), do: Map.put(attrs, :location, "")
  def default_location(attrs), do: attrs

  def get_or_create_by(tracking_codes) do
    ch = build_from_attrs(tracking_codes)
    key = cache_key(ch)

    case cache_lookup(key) do
      {:hit, source} ->
        {:ok, source}

      :miss ->
        single_flight(key, fn -> fetch_source(ch, key) end)
    end
  end

  ###### Caching ######

  # Small TTL cache for the per-request source lookup. Sources are append-only
  # and never deleted, so the cache is a pure memory optimisation: TTL + size
  # cap bound memory, not correctness. A miss is single-flighted through a
  # per-key Registry so a burst of concurrent requests for the same source does
  # NOT all race to the DB (which caused multixact/SLRU contention); one process
  # does the DB work, the rest wait for the cached result.

  # Race-tolerant table creation. Under a burst of concurrent requests two
  # callers can both see the table as undefined and try to create it; the loser
  # would crash with "table name already exists". Rescuing that and reusing the
  # existing table keeps lazy creation safe.
  defp ensure_cache_table do
    case :ets.whereis(@cache_table) do
      :undefined ->
        try do
          :ets.new(@cache_table, [:named_table, :public, :set, read_concurrency: true])
        rescue
          ArgumentError -> @cache_table
        end

      _table ->
        @cache_table
    end
  end

  defp cache_key(ch) do
    {get_field(ch, :source), get_field(ch, :medium), get_field(ch, :campaign),
     get_field(ch, :content), get_field(ch, :location)}
  end

  defp cache_lookup(key) do
    ensure_cache_table()
    now = System.monotonic_time(:millisecond)

    case :ets.lookup(@cache_table, key) do
      [{^key, source, expires_at}] when expires_at > now ->
        {:hit, source}

      [{^key, _source, _expires_at}] ->
        :ets.delete(@cache_table, key)
        :miss

      [] ->
        :miss
    end
  end

  defp cache_put(key, source) do
    ensure_cache_table()
    trim_if_needed()
    expires_at = System.monotonic_time(:millisecond) + @cache_ttl_ms
    :ets.insert(@cache_table, {key, source, expires_at})
    :ok
  end

  # Single-flight: only one process performs the DB work per key. Followers
  # poll the cache for the result; if the leader dies before populating, they
  # retry the claim (bounded) and then fall back to doing the work themselves.
  defp single_flight(key, fun, retries \\ 2)

  defp single_flight(key, fun, retries) do
    case Registry.register(@registry, key, nil) do
      {:ok, _pid} ->
        try do
          fun.()
        after
          Registry.unregister(@registry, key)
        end

      {:error, {:already_registered, _pid}} ->
        case wait_for_cache(key, @lock_wait_timeout_ms) do
          {:ok, source} ->
            {:ok, source}

          :timeout when retries > 0 ->
            single_flight(key, fun, retries - 1)

          :timeout ->
            fun.()
        end
    end
  end

  defp wait_for_cache(key, timeout_ms) do
    deadline = System.monotonic_time(:millisecond) + timeout_ms
    do_wait_for_cache(key, deadline)
  end

  defp do_wait_for_cache(key, deadline) do
    case cache_lookup(key) do
      {:hit, source} ->
        {:ok, source}

      :miss ->
        if System.monotonic_time(:millisecond) >= deadline do
          :timeout
        else
          Process.sleep(@poll_interval_ms)
          do_wait_for_cache(key, deadline)
        end
    end
  end

  defp fetch_source(ch, key) do
    case ch
         |> Repo.insert(
           on_conflict: [set: [updated_at: DateTime.utc_now()]],
           conflict_target: [:source, :medium, :campaign, :content, :location]
         ) do
      {:ok, source} ->
        cache_put(key, source)
        {:ok, source}

      {:error, _} = e ->
        e
    end
  end

  # Bounds memory: when the table reaches the cap, keep only the newest
  # (largest expires_at) non-expired entries. Runs only on a cache miss.
  defp trim_if_needed do
    if :ets.info(@cache_table, :size) >= @max_cache_entries do
      now = System.monotonic_time(:millisecond)

      keep =
        @cache_table
        |> :ets.tab2list()
        |> Enum.filter(fn {_k, _v, expires_at} -> expires_at > now end)
        |> Enum.sort_by(&elem(&1, 2), :desc)
        |> Enum.take(max(@max_cache_entries - 1, 0))

      :ets.delete_all_objects(@cache_table)
      Enum.each(keep, fn entry -> :ets.insert(@cache_table, entry) end)
    end
  end

  def well_formed_url?(%URI{host: h, path: p, scheme: s})
      when h != nil and h != "" and p != nil and s in ["https", "http", "ws", "wss"],
      do: true

  def well_formed_url?(_), do: false

  def strip_url(%URI{host: h, path: p, scheme: s, port: prt}) do
    %URI{
      host: h,
      path: p,
      scheme: s,
      port: prt
    }
    |> URI.to_string()
  end

  @doc """
  Get location from http referer header and location explicitly sent by user.
  As this is possible to get
  """
  def get_tracking_location(location, referer)
      when is_bitstring(location) and is_bitstring(referer) do
    loc_uri = URI.parse(location)
    ref_uri = URI.parse(referer)
    referer = strip_url(ref_uri)

    if well_formed_url?(ref_uri) do
      if well_formed_url?(loc_uri) do
        if String.starts_with?(location, referer) do
          strip_url(loc_uri)
        else
          Sentry.capture_message(
            "Tracking location '#{location}' does not start with '#{referer}'",
            result: :none
          )

          # the location provided is outside of the referer scope. Use referer
          strip_url(ref_uri)
        end
      else
        strip_url(ref_uri)
      end
    else
      nil
    end
  end

  def get_tracking_location(nil, referer) when is_bitstring(referer) do
    ref_uri = URI.parse(referer)

    if well_formed_url?(ref_uri) do
      referer
    else
      nil
    end
  end

  def get_tracking_location(_, _), do: nil
end
