defmodule Proca.Server.MTT do
  @moduledoc """
  Setup GenServer to run every 5 minutes to check if there are any emails to send
  """
  use GenServer

  import Ecto.Query
  alias Proca.Repo
  alias Proca.Server.MTTWorker

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    :timer.send_interval(10_000, :work)
    {:ok, state}
  end

  def dupe_rank() do
    sql = """
    UPDATE messages
    SET dupe_rank = ranked.dupe_rank
    FROM
    (
    SELECT
            m.id,
            rank() OVER (PARTITION BY s.fingerprint, a.campaign_id ORDER BY a.inserted_at) - 1 as dupe_rank
        FROM messages m JOIN actions a ON m.action_id = a.id JOIN supporters s ON a.supporter_id = s.id
        WHERE fingerprint IN (
            SELECT s.fingerprint
            FROM messages m JOIN actions a ON m.action_id = a.id JOIN supporters s ON a.supporter_id = s.id
            WHERE m.dupe_rank is NULL
        )
    ) ranked
    WHERE messages.id = ranked.id ;
    """

    Ecto.Adapters.SQL.query(Proca.Repo, sql)
  end

  @impl true
  def handle_info(:work, state) do
    dupe_rank()
    process_mtt()
    MTTWorker.process_mtt_test_mails()
    {:noreply, state}
  end

  # XXX
  # def dedupe_mtt() - calculate dupe_rank
  # do not process a NULL dupe_rank

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
      Task.async(fn ->
        MTTWorker.process_mtt_campaign(campaign)
      end)
    end)
    |> Enum.map(&Task.await/1)
  end
end
