defmodule Proca.Server.MTT do
  @moduledoc """
  Built-in service to send MTT emails to targets.any()

  This email sender works independently of queue-bound email supporter worker,
  because it is time-bound, sends according to schedule.

  This server runs every 30 seconds or more (under load).

  I every run, it will:

  1. Calculate `dupeRank` for the MTT messages
  2. For every campaign for which today falls into day range of sending MTT, launch `Proca.Server.MTTWorker`
  3. Send out all the test MTT's instantly
  4. Wait untill all `Proca.Server.MTTWorker` finish
  """
  use GenServer

  import Logger
  import Ecto.Query
  alias Proca.Repo
  alias Proca.Server.MTTWorker

  @interval 30_000

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
    sql = """
    UPDATE messages
    SET dupe_rank = ranked.dupe_rank
    FROM
    (
    SELECT
            m.id,
            rank() OVER (PARTITION BY s.fingerprint, m.target_id ORDER BY a.inserted_at) - 1 as dupe_rank
        FROM messages m JOIN actions a ON m.action_id = a.id JOIN supporters s ON a.supporter_id = s.id
        WHERE fingerprint IN (
            SELECT s.fingerprint
            FROM messages m JOIN actions a ON m.action_id = a.id JOIN supporters s ON a.supporter_id = s.id
            WHERE m.dupe_rank is NULL
        ) AND a.processing_status = 4 AND s.processing_status = 3
    ) ranked
    WHERE messages.id = ranked.id ;
    """

    Ecto.Adapters.SQL.query(Proca.Repo, sql)
  end

  @impl true
  def handle_info(:work, %{workers: w}) do
    dupe_rank()
    workers = w ++ process_mtt()
    MTTWorker.process_mtt_test_mails()

    if workers == [] do
      # all workers done already (there will be no :DOWN info)
      schedule_work()
    end

    {:noreply, %{workers: workers}}
  end

  @impl true
  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _reason}, %{workers: workers}) do
    workers = List.delete(workers, ref)

    Logger.info("MTT Worker finished #{inspect(ref)} - remained #{length(workers)} workers running")

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
        where: mtt.start_at <= from_now(0, "day") and mtt.end_at >= from_now(0, "day"),
        preload: [:mtt],
        order_by: fragment("RANDOM()")
      )
      |> Repo.all()

    Enum.map(running_mtts, fn campaign ->
      Logger.info("Start MTT worker for #{campaign.name} (waiting for connection pool)")
      # We are compeeting for connection pool with the web server here, at one point we must get the connection
      task =
        Task.async(fn ->
          Repo.checkout(fn -> 
            Logger.info("Start MTT worker for #{campaign.name} (connection acquired)")
            MTTWorker.process_mtt_campaign(campaign) 
          end, timeout: :infinity)
        end)

      task.ref
    end)
  end
end
