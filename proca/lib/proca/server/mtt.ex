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

  @impl true
  def handle_info(:work, state) do
    process_mtt()
    {:noreply, state}
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
      Task.async(fn ->
        MTTWorker.process_mtt_campaign(campaign)
      end)
    end)
    |> Enum.map(&Task.await/1)
  end
end
