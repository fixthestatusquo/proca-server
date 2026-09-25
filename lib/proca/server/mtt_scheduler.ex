defmodule Proca.Server.MTTScheduler do
  @moduledoc """
  Sends a single target's pending messages, spread evenly over the send window.

  The window is split into `n` equal buckets for `n` messages and message `i` is
  dispatched at a random moment inside bucket `i`. One rule for every `n`: a lone
  message lands at a random point in the whole window, six messages land roughly
  one per sixth of it. No message is sent at the same fixed offset, and every
  message stays inside its own bucket.

  Delivery itself goes through the org's `wrk.N.mtt` RabbitMQ queue (consumed
  by `Proca.Stage.MTT`); see `Proca.Server.MTTContext.dispatch_message/2`.
  """

  use GenServer
  require Logger

  alias Proca.Server.MTTContext

  # 55 min, not a full 60: leaves a gap before the next `MTTHourlyCron` tick so a
  # target never has two scheduler runs overlapping (the target is registered, so
  # an overlap would be skipped, delaying that target's next batch by an hour).
  @send_window_ms 55 * 60 * 1000

  def start_link(target, max_emails_per_hour, opts \\ []) do
    GenServer.start_link(__MODULE__, {target, max_emails_per_hour}, opts)
  end

  @impl true
  def init({target, max_emails_per_hour}) do
    start_time = System.monotonic_time()

    messages = MTTContext.get_pending_messages(target.id, max_emails_per_hour)
    pending_count = length(messages)
    stop_reason = if pending_count == 0, do: :no_messages, else: :sending

    :telemetry.execute(
      [:mtt, :throttle, :scheduler, :start],
      %{pending_count: pending_count},
      %{
        target_id: target.id,
        campaign_id: target.campaign.id,
        campaign_name: target.campaign.name
      }
    )

    state = %{
      target: target,
      messages: messages,
      waits: bucket_waits(pending_count, @send_window_ms),
      start_time: start_time,
      sent_count: 0,
      stop_reason: stop_reason
    }

    # With no messages, tick once so the process stops through the empty clause
    # and `terminate/2` still emits the matching `:stop` telemetry.
    if pending_count == 0 do
      send(self(), :send_message)
      {:ok, state}
    else
      {:ok, schedule_next(state)}
    end
  end

  @impl true
  def handle_info(:send_message, %{messages: [msg | rest], waits: [_wait | waits]} = state) do
    Task.start(fn -> MTTContext.dispatch_message(state.target, msg) end)

    state = %{state | messages: rest, waits: waits, sent_count: state.sent_count + 1}

    case waits do
      [] -> {:stop, :normal, %{state | stop_reason: :all_sent}}
      _ -> {:noreply, schedule_next(state)}
    end
  end

  def handle_info(:send_message, %{messages: []} = state) do
    Logger.info("MTT scheduler target #{state.target.id}: no messages, stopping")
    {:stop, :normal, state}
  end

  @impl true
  def terminate(reason, state) do
    duration = System.monotonic_time() - state.start_time

    stop_reason =
      case reason do
        :normal -> state.stop_reason
        :shutdown -> :shutdown
        _ -> :crashed
      end

    :telemetry.execute(
      [:mtt, :throttle, :scheduler, :stop],
      %{duration: duration, messages_sent: state.sent_count},
      %{
        target_id: state.target.id,
        campaign_id: state.target.campaign.id,
        campaign_name: state.target.campaign.name,
        stop_reason: stop_reason
      }
    )

    :ok
  end

  defp schedule_next(%{waits: [wait | _]} = state) do
    Process.send_after(self(), :send_message, wait)
    state
  end

  @doc """
  Waiting time (ms) before each of `count` messages.

  `window_ms` is split into `count` equal buckets; each returned wait reaches a
  random moment inside that message's bucket (differences of the per-message
  offsets, so they can be fed to `Process.send_after/3` in order).
  """
  def bucket_waits(count, _window_ms) when count <= 0, do: []

  def bucket_waits(count, window_ms) do
    bucket = max(div(window_ms, count), 1)

    offsets =
      for i <- 0..(count - 1) do
        i * bucket + :rand.uniform(bucket) - 1
      end

    [first | rest] = offsets
    [first | Enum.zip_with(offsets, rest, fn a, b -> b - a end)]
  end
end
