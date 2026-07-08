defmodule Proca.Server.MTTScheduler do
  @moduledoc """
  Sending messages for a single target, spreading them over 1 hour with randomness.
  """

  use GenServer
  require Logger

  alias Proca.Server.MTTContext

  @one_hour_ms 55 * 60 * 1000

  def start_link(target, max_emails_per_hour, opts \\ []) do
    GenServer.start_link(__MODULE__, {target, max_emails_per_hour}, opts)
  end

  @impl true
  def init({target, max_emails_per_hour}) do
    start_time = System.monotonic_time()

    Task.start(fn -> MTTContext.process_test_mails(target) end)

    messages = MTTContext.get_pending_messages(target.id, max_emails_per_hour)

    pending_count = Enum.count(messages)
    stop_reason = if pending_count == 0, do: :no_messages, else: :sending

    :telemetry.execute(
      [:proca, :mtt_new, :scheduler, :start],
      %{pending_count: pending_count},
      %{
        target_id: target.id,
        campaign_id: target.campaign.id,
        campaign_name: target.campaign.name
      }
    )

    send(self(), {:send_message})

    {:ok,
     %{
       target: target,
       messages: messages,
       jitter_toggle: true,
       count: pending_count,
       start_time: start_time,
       sent_count: 0,
       stop_reason: stop_reason
     }}
  end

  @impl true
  def handle_info({:send_message}, %{messages: [], stop_reason: :no_messages} = state) do
    Logger.info("No messages to send for #{state.target.id}, stopping scheduler")

    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:send_message}, %{messages: []} = state) do
    Logger.info("All messages sent for #{state.target.id}, stopping scheduler")

    {:stop, :normal, %{state | stop_reason: :all_sent}}
  end

  @impl true
  def handle_info(
        {:send_message},
        %{target: target, messages: [msg | rest], jitter_toggle: jitter_toggle} = state
      ) do
    Task.start(fn ->
      MTTContext.deliver_message(target, msg)
    end)

    interval = calc_interval(state.count, jitter_toggle, length(rest))

    Logger.info("Messages interval #{interval} ms for target #{target.id}")

    Process.send_after(self(), {:send_message}, interval)

    {:noreply,
     %{state | messages: rest, jitter_toggle: not jitter_toggle, sent_count: state.sent_count + 1}}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    Logger.info("MTTNew down ref #{inspect(ref)} reason #{inspect(reason)}")

    {:noreply, state}
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
      [:proca, :mtt_new, :scheduler, :stop],
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

  def calc_interval(messages_count, _, 1)
      when messages_count > 1 and rem(messages_count, 2) == 0 do
    div(@one_hour_ms, max(messages_count - 1, 1))
  end

  def calc_interval(messages_count, jitter_toggle, left_messages_count)
      when messages_count > 1 and left_messages_count > 0 do
    base = div(@one_hour_ms, max(messages_count - 1, 1))

    # +/- 25%
    jitter_amount = div(base, 4)
    jitter = if jitter_toggle, do: jitter_amount, else: -jitter_amount

    # at least 1s
    max(base + jitter, 1000)
  end

  def calc_interval(_, _, _), do: 1000
end
