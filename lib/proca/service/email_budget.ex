defmodule Proca.Service.EmailBudget do
  @moduledoc """
  Tracks, in memory, how many transactional emails have been sent per org via
  the org's `transactional_email_backend`. This lets an org "warm up" a new
  sending backend, or cap its usage, for the first N emails and then fall
  back to `email_backend` for the rest - see `Proca.Org.for_transactional_email/2`.

  Counts live only in an ETS table (no DB writes on every send), so a burst
  of concurrent sends doesn't serialize through a process mailbox or queue up
  behind a DB write. Counts reset to zero on application restart, which is
  fine since warming/budget tracking doesn't need to be exact.
  """
  use GenServer

  @table __MODULE__

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    :ets.new(@table, [:set, :public, :named_table, write_concurrency: true])
    {:ok, %{}}
  end

  @doc """
  Atomically adds `count` to the running total for `org_id` and returns the
  new total. Safe to call concurrently from many processes - does not go
  through the GenServer.
  """
  def add(org_id, count \\ 1) do
    :ets.update_counter(@table, org_id, {2, count}, {org_id, 0})
  end

  @doc "Current total for org_id, without incrementing it."
  def count(org_id) do
    case :ets.lookup(@table, org_id) do
      [{^org_id, count}] -> count
      [] -> 0
    end
  end

  @doc "Resets the count for org_id back to zero. Mostly useful in tests."
  def reset(org_id) do
    :ets.delete(@table, org_id)
    :ok
  end
end
