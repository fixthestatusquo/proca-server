defmodule Proca.Stage.MTTTest do
  @moduledoc """
  Global low-volume consumer for MTT testing actions.

  One event represents one testing action. The database remains the source of
  truth and `MTTContext.deliver_test_mails/1` caps output to one email per locale.
  """

  use Broadway

  alias Broadway.Message
  alias Proca.Server.MTTContext
  import Proca.Stage.Support, only: [ignore: 2]

  def start_link(_opts) do
    if Proca.Server.MTT.mode() == :enabled do
      Broadway.start_link(__MODULE__,
        name: __MODULE__,
        producer: [
          module: {
            BroadwayRabbitMQ.Producer,
            queue: Proca.Pipes.Topology.mtt_test_queue(),
            connection: Proca.Pipes.Connection.connection_url(),
            declare: [durable: true],
            qos: [prefetch_count: 5],
            on_failure: :reject_and_requeue_once,
            metadata: [:headers]
          },
          concurrency: 1
        ],
        processors: [default: [concurrency: 1]]
      )
    else
      :ignore
    end
  end

  @impl true
  def handle_message(_, message = %Message{data: data}, _) do
    case JSON.decode(data) do
      {:ok, %{"actionId" => action_id, "testing" => true}} ->
        case MTTContext.deliver_test_mails(action_id) do
          :ok -> message
          {:error, reason} -> Message.failed(message, inspect(reason))
        end

      {:ok, _} ->
        ignore(message, "Invalid MTT test message format")

      {:error, reason} ->
        ignore(message, reason)
    end
  end
end
