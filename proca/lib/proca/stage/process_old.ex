defmodule Proca.Stage.ProcessOld do
  @moduledoc """

  Server which processes older actions, which might be unprocessed because of
  not queue was available, or processing failed.

  We process the actions one by one synchronously because the processing will
  update the associated supporter.

  We use thre intervals to control processing of old actions:

  - @time_margin - (1 minute default) - do not process actions more recent then
    one minute - they might be actually still processed by async-after-add processing.

  - interval (given as argument to ProcessOld.start_link, 30 sec default) - how often should we check for old actions

  - @batch_interval (1 second default) - how long to wait between processing of 1000 actions batch.

  """
  import Proca.Repo
  import Ecto.Query, only: [from: 2]
  import Logger
  use GenServer

  # @interval 30 * 1000
  @batch_interval 1000

  @time_margin "1 minute"
  @batch_size 1000

  @impl true
  def init(interval) when is_integer(interval) do
    if interval > 0 do
      process_in(interval)
    end

    {:ok, %{interval: interval}}
  end

  def start_link(interval) do
    GenServer.start_link(__MODULE__, interval, name: __MODULE__)
  end

  @impl true
  def handle_info(:process, st) do
    if Proca.Pipes.Connection.is_connected?() do
      processed_no = process_batch()
      process_in(if processed_no == 0, do: st[:interval], else: @batch_interval)
    else
      process_in(st[:interval])
    end

    {:noreply, st}
  end

  def process_batch() do
    action_ids = unprocessed_ids()
    debug("Stage.ProcessOld: #{length(action_ids)} unprocessed actions to process")

    for a_id <- action_ids do
      action =
        one(
          from(a in Proca.Action,
            where: a.id == ^a_id,
            preload: [action_page: [:org, :campaign], supporter: :contacts]
          )
        )

      Proca.Stage.Action.process(action)
    end

    length(action_ids)
  end

  def unprocessed_ids do
    from(a in Proca.Action,
      join: s in Proca.Supporter,
      on: a.supporter_id == s.id,
      where:
        a.inserted_at < fragment("NOW() - INTERVAL ?", @time_margin) and
          ((a.processing_status == :new and s.processing_status == :new) or
             (a.processing_status == :new and s.processing_status == :accepted) or
             (a.processing_status == :accepted and s.processing_status == :accepted)),
      limit: @batch_size,
      select: a.id
    )
    |> all()
  end

  defp process_in(interval) do
    Process.send_after(self(), :process, interval)
  end
end
