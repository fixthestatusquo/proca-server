defmodule Proca.Server.MTT do
  @moduledoc """
  Setup GenServer to run every 5 minutes to check if there are any emails to send
  """
  use GenServer

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
    {:noreply, %{workers: workers}}
  end

  @impl true
  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, _reason}, %{workers: workers}) do
    workers = List.delete(workers, ref)

    if workers == [] do
      # all workers done
      schedule_work()
    end

    {:noreply, %{workers: workers}}
  end

  def process_mtt() do
    # fetch campaigns to process here
    running_mtts =
      from(c in Proca.Campaign,
        join: mtt in Proca.MTT,
        on: mtt.campaign_id == c.id,
        where: mtt.start_at <= from_now(0, "day") and mtt.end_at >= from_now(0, "day"),
        preload: [:mtt]
      )
      |> Repo.all()

    Enum.map(running_mtts, fn campaign ->
      task =
        Task.async(fn ->
          MTTWorker.process_mtt_campaign(campaign)
        end)

      task.ref
    end)
  end
end
