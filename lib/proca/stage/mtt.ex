defmodule Proca.Stage.MTT do
  @moduledoc """
  Broadway stage delivering MTT emails from the `wrk.N.mtt` RabbitMQ queue.

  `{messageId, targetId}` payloads are published by the live-send paths, which decide
    *when* a message goes out: `Proca.Server.MTTScheduler` (no-drip, spread
    over the hour) and `Proca.Server.MTTWorker` (drip, proportional cycles);
  This stage does the actual email delivery via `Proca.Server.MTTContext`.

  The messages table remains the source of truth: the message is re-fetched
  and its `sent` flag re-checked at consume time, so a re-delivered or
  re-published queue message is ignored. A message rejected here stays unsent
  in the DB and is re-dispatched by the next hourly cron run.
  """
  use Broadway

  alias Broadway.Message
  alias Proca.Org
  alias Proca.Server.MTTContext
  import Proca.Stage.Support, only: [ignore: 1, ignore: 2, too_many_retries?: 1]
  import Logger

  def start_for?(org),
    do: Proca.Server.MTT.mode() == :enabled and Proca.Stage.EmailSupporter.start_for?(org)

  def start_link(org = %Org{id: org_id}) do
    Broadway.start_link(__MODULE__,
      name: String.to_atom(Atom.to_string(__MODULE__) <> ".#{org_id}"),
      producer: [
        module: Proca.Pipes.Topology.broadway_producer(org, "mtt"),
        concurrency: 1
      ],
      processors: [
        # ponytail: concurrency 1 keeps the unsent-flag recheck race-free per org
        default: [concurrency: 1]
      ]
    )
  end

  @impl true
  def handle_message(_, message = %Message{data: data}, _) do
    case JSON.decode(data) do
      {:ok, %{"messageId" => message_id, "targetId" => target_id}} ->
        if too_many_retries?(message) do
          Logger.error("MTT retry limit exceeded for message #{message_id}")
          MTTContext.emit_delivery(:discarded, reason: :retry_limit_exceeded)
          message
        else
          case deliver(message_id, target_id) do
            :ok -> message
            :ignore -> ignore(message)
            {:discard, reason} -> ignore(message, inspect(reason))
            {:error, reason} -> Message.failed(message, inspect(reason))
          end
        end

      {:ok, _} ->
        warn("MTT wrk: Invalid message format #{data}")
        ignore(message, "Invalid message format")

      {:error, reason} ->
        ignore(message, reason)
    end
  end

  @doc """
  Deliver one MTT message. Returns `:ignore` when the message is already
  sent/gone or the target is no longer deliverable (no email backend).
  """
  def deliver(message_id, target_id) do
    MTTContext.deliver_queued_message(message_id, target_id)
  end
end
