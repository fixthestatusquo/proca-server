defmodule Proca.Server.MTTScheduler do
  @moduledoc """
  Sending messages for a single target, spreading them over 1 hour with randomness.
  """

  use GenServer
  require Logger

  alias Proca.Server.MTTContext

  @one_hour_ms 55 * 60 * 1000

  def start_link(target, max_emails_per_hour) do
    GenServer.start_link(__MODULE__, {target, max_emails_per_hour})
  end

  @impl true
  def init({target, max_emails_per_hour}) do
    Task.start(fn -> MTTContext.process_test_mails(target) end)

    messages = MTTContext.get_pending_messages(target.id, max_emails_per_hour)

    send(self(), {:send_message})

    {:ok, %{target: target, messages: messages, jitter_toggle: true, count: Enum.count(messages)}}
  end

  @impl true
  def handle_info({:send_message}, %{messages: []} = state) do
    Logger.info("No messages to send for #{state.target.id}, stopping scheduler")

    {:stop, :normal, %{state | count: 0}}
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

    {:noreply, %{state | messages: rest, jitter_toggle: not jitter_toggle}}
  end

  @impl true
  def handle_info({:DOWN, ref, _, _, reason}, state) do
    Logger.info("MTTNew down ref #{inspect(ref)} reason #{inspect(reason)}")

    {:noreply, state}
  end

  def calc_interval(messages_count, _, 1) when messages_count > 1 and rem(messages_count, 2) == 0 do
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
