defmodule Proca.Server.MTT do
  @moduledoc """
  Built-in service to send MTT emails to targets.any()

  This email sender works independently of queue-bound email supporter worker,
  because it is time-bound, sends according to schedule.

  This server runs every 3 minutes or more (under load).

  I every run, it will:

  1. Calculate `dupeRank` for the MTT messages
  2. For every campaign for which today falls into day range of sending MTT, launch `Proca.Server.MTTWorker`
  3. Publish regular MTT messages to per-org RabbitMQ queues
  4. Wait until all `Proca.Server.MTTWorker` tasks finish

  Testing actions are published independently to `wrk.mtt.test` when their
  processing reaches the delivered stage.
  """
  use GenServer

  require Logger
  import Ecto.Query
  alias Proca.Repo
  alias Proca.Server.{MTTWorker, MTTContext}

  @interval 180_000

  @type mode :: :enabled | :disabled | :dry_run

  @spec mode() :: mode()
  def mode do
    Application.get_env(:proca, __MODULE__, [])
    |> Keyword.get(:mode, :enabled)
  end

  def enabled?, do: mode() in [:enabled, :dry_run]
  def dry_run?, do: mode() == :dry_run

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_) do
    schedule_work()
    {:ok, %{workers: []}}
  end

  defp schedule_work() do
    Logger.info("Schedule next MTT run in #{@interval}")
    Process.send_after(self(), :work, @interval)
  end

  def dupe_rank() do
    MTTContext.dupe_rank()
  end

  @impl true
  def handle_info(:work, %{workers: w}) do
    workers =
      if enabled?() do
        dupe_rank()
        w ++ process_mtt()
      else
        w
      end

    if workers == [] do
      # all workers done already (there will be no :DOWN info)
      schedule_work()
    end

    {:noreply, %{workers: workers}}
  rescue
    e in DBConnection.ConnectionError ->
      Logger.warning("MTT work cycle skipped: DB connection error: #{Exception.message(e)}")
      schedule_work()
      {:noreply, %{workers: w}}
  end

  @impl true
  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _reason}, %{workers: workers}) do
    workers = List.delete(workers, ref)

    Logger.info(
      "MTT Worker finished #{inspect(ref)} - remained #{length(workers)} workers running"
    )

    if workers == [] do
      # all workers done
      schedule_work()
    end

    {:noreply, %{workers: workers}}
  end

  def process_mtt() do
    # fetch campaigns to process here
    # use random so when many mtts run, we compete for the connection pool in fair way
    running_mtts =
      from(c in Proca.Campaign,
        join: mtt in Proca.MTT,
        on: mtt.campaign_id == c.id,
        where:
          c.status == :live and
            mtt.drip_delivery == true and
            mtt.start_at <= from_now(0, "day") and
            mtt.end_at >= from_now(0, "day"),
        preload: [:mtt],
        order_by: fragment("RANDOM()")
      )
      |> Repo.all()

    Enum.map(running_mtts, fn campaign ->
      Logger.info("Start MTT worker for #{campaign.name} (waiting for connection pool)")

      # We are compeeting for connection pool with the web server here, at one point we must get the connection
      task =
        Task.async(fn ->
          Repo.checkout(
            fn ->
              Logger.info("Start MTT worker for #{campaign.name} (connection acquired)")
              MTTWorker.process_mtt_campaign(campaign)
            end,
            timeout: :infinity
          )
        end)

      task.ref
    end)
  end
end
