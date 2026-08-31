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
  @counter_table :source_cache_counter

  # Static, inlined TTL (milliseconds) for a cached source — deliberately a
  # compile-time constant so the hot path pays nothing for it. Sources are
  # append-only, immutable-key lookup rows, so caching them is safe.
  @cache_ttl_ms :timer.seconds(30)

  # Bounds cache growth so the table cannot grow without limit even when many
  # distinct sources (e.g. unique referers) arrive. The check is gated by a
  # counter so it runs only ~1 in @size_check_every writes, keeping it off the
  # hot path; when exceeded the table is cleared (sources are cheap to
  # re-fetch on a subsequent miss).
  @max_cache_entries 100_000
  @size_check_every 512

  defp maybe_trim do
    n = :ets.update_counter(@counter_table, :writes, 1, {:writes, 0})

    if rem(n, @size_check_every) == 0 and :ets.info(@cache_table, :size) >= @max_cache_entries do
      :ets.delete_all_objects(@cache_table)
    end
  end

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
        case ch
             |> Repo.insert(
               on_conflict: :nothing,
#               on_conflict: [set: [updated_at: DateTime.utc_now()]],
               conflict_target: [:source, :medium, :campaign, :content, :location]
             ) do
          {:ok, %{id: nil}} ->
            source = Repo.get_by!(Source,
              source: ch.source,
              medium: ch.medium,
              campaign: ch.campaign,
              content: ch.content,
              location: ch.location
            )

            cache_put(key, source)
            {:ok, source}

          {:ok, source} = ok ->
            cache_put(key, source)
            ok

          {:error, _} = e ->
            e
        end
    end
  end

  ###### Caching ######

  # Small TTL cache for the per-request source upsert. A burst of signatures
  # sharing the same UTM/referer currently does an INSERT (with on_conflict) for
  # every request; caching the resulting Source for a short TTL lets those
  # repeat requests skip the write entirely. Correctness is unaffected because
  # the DB `on_conflict` insert remains the source of truth on a miss.

  # Race-tolerant table creation. Under a burst of concurrent requests two
  # callers can both see the table as undefined and try to create it; the loser
  # would crash with "table name already exists". Rescuing that and reusing the
  # existing table keeps lazy creation safe.
  defp ensure_cache_table do
    case :ets.whereis(@cache_table) do
      :undefined ->
        try do
          :ets.new(@cache_table, [:named_table, :public, :set, read_concurrency: true])
          ensure_counter_table()
          @cache_table
        rescue
          ArgumentError -> @cache_table
        end

      _table ->
        @cache_table
    end
  end

  # Fixed-name counter table for the low-frequency size check; created alongside
  # the cache table.
  defp ensure_counter_table do
    case :ets.whereis(@counter_table) do
      :undefined ->
        try do
          :ets.new(@counter_table, [:named_table, :public, :set])
        rescue
          ArgumentError -> @counter_table
        end

      _ -> @counter_table
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

    maybe_trim()
    expires_at = System.monotonic_time(:millisecond) + @cache_ttl_ms
    :ets.insert(@cache_table, {key, source, expires_at})
    :ok
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
