defmodule Proca.ActionPage.Status do
  @moduledoc """
  Server which tracks and monitors active pages.

  Stored maps:
  - last_seen_at: action page id -> last action inserted_at date time
  - last_seen_location: action page id -> last action location (if provided in http referer)

  The maps are loaded from DB on start and then are updated in-memory on action creation.
  Action Pages inactive for more then 1 year are ignored.

  API:
  - Proca.ActionPage.Status.get_last_at(id) - returns NativeDateTime of last activity or nil if recently not active
  - Proca.ActionPage.Status.get_last_location(id) - returns last location or nil if not known


  """
  use GenServer

  import Ecto.Query
  import Proca.Repo, only: [all: 1, one: 1]

  alias Proca.Action

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    last_seen_at = :ets.new(:last_seen_at, [:set, :protected, :named_table])
    last_seen_location = :ets.new(:last_seen_location, [:set, :protected, :named_table])

    {:ok,
     %{
       last_seen_at: last_seen_at,
       last_seen_location: last_seen_location
     }, {:continue, :load_last_seen}}
  end

  @impl true
  def handle_continue(:load_last_seen, s) do
    rows =
      all(
        from(a in Action,
          left_join: s in assoc(a, :source),
          order_by: [desc: a.id],
          where: a.inserted_at >= fragment("current_date - interval '1 year'"),
          select: [a.action_page_id, a.inserted_at, s.location],
          distinct: [a.action_page_id]
        )
      )

    :ets.insert(:last_seen_at, Enum.map(rows, fn [id, at, _lo] -> {id, at} end))
    :ets.insert(:last_seen_location, Enum.map(rows, fn [id, _at, lo] -> {id, lo} end))

    {:noreply, s}
  end

  @impl true
  def handle_cast(
        {:action,
         action = %Action{
           id: _id,
           action_page_id: ap_id,
           inserted_at: seen_at
         }},
        s
      ) do
    :ets.insert(:last_seen_at, {ap_id, seen_at})

    if action.source_id != nil do
      source = one(Ecto.assoc(action, :source))

      if source.location != "" do
        :ets.insert(:last_seen_location, {ap_id, source.location})
      end
    end

    {:noreply, s}
  end

  def track_action(action = %Action{}) do
    GenServer.cast(__MODULE__, {:action, action})
  end

  @spec activity(number) :: :inactive | {:active, NaiveDateTime, String.t() | nil}
  def activity(action_page_id) when is_number(action_page_id) do
    case get_last_at(action_page_id) do
      nil -> :inactive
      seen_at -> {:active, seen_at, get_last_location(action_page_id)}
    end
  end

  def get_last_at(id) do
    case :ets.lookup(:last_seen_at, id) do
      [] -> nil
      [{_id, seen_at}] -> seen_at
    end
  end

  def get_last_location(id) do
    case :ets.lookup(:last_seen_location, id) do
      [] -> nil
      [{_id, location}] -> location
    end
  end
end
