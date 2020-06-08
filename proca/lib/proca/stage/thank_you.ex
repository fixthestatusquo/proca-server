defmodule Proca.Stage.ThankYou do
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Action,Org}

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
                 queue: "system.email.thankyou",
                 connection: Proca.Server.Plumbing.connection_url(),
                 qos: [
                   prefetch_count: 10,
                 ]
                },
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ],
      batchers: [
        ses: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 1
        ]
      ]
    )
  end

  @impl true
  def handle_message(_, %Message{data: data} = message, _) do
    case JSON.decode(data) do
      {:ok, %{"actionPageId" => action_page_id} = action} ->
        message
        |> Message.update_data(fn _ -> action end)
        |> Message.put_batch_key(action_page_id)
        |> Message.put_batcher(:ses)
      {:error, reason} -> Message.failed(message, reason)
    end
  end

  @impl true
  def handle_batch(:ses, messages, %BatchInfo{batch_key: _action_page_id}, _) do
    messages
  end

end
