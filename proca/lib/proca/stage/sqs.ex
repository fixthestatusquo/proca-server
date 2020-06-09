defmodule Proca.Stage.SQS do
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Action,Org,Service}
  import Ecto.Query, only: [from: 2]
  alias Proca.Stage.Support


  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {BroadwayRabbitMQ.Producer,
                 queue: "system.sqs",
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
        sqs: [
          batch_size: 10,
          batch_timeout: 1_000,
          concurrency: 1
        ]
      ]
    )
  end


  @impl true
  def handle_message(_, %Message{data: data} = message, _) do
    case JSON.decode(data) do
      {:ok, %{"orgId" => org_id} = action} ->
        message
        |> Message.update_data(fn _ -> action end)
        |> Message.put_batch_key(org_id)
        |> Message.put_batcher(:sqs)
      {:error, reason} -> Message.failed(message, reason)
    end
  end


  @impl true
  def handle_batch(_sqs, msgs, %BatchInfo{batch_key: org_id}, _) do
    with service when not is_nil(service) <- Service.get_one_for_org("sqs", %Org{id: org_id}),
         action_ids <- Enum.map(msgs, fn m -> m.data["actionId"] end),
         actions <- Support.bulk_actions_data(action_ids) |> Enum.map(&to_message/1)
      do

      case ExAws.SQS.send_message_batch(service.path, actions)
      |> Service.aws_request(service)
      do
      {:ok, status} -> msgs |> mark_failed(status)
      _ -> msgs |> Enum.map(fn m -> Message.failed(m, "Cannot call SQS.SendMessageBatch") end)
      end
    else
      _ -> {:error, "SQS service not configured for org_id #{org_id}"}
    end
  end

  def to_message(body) do
    {:ok, payload} = JSON.encode(body)
    [id: body["actionId"], message_body: payload]
  end

  def mark_failed(messages, %{body: %{failures: fails}}) do
    reasons = Enum.reduce(fails, %{}, fn %{id: id, message: msg}, acc -> Map.put(acc, String.to_integer(id), msg) end)
    messages
    |> Enum.map(fn m ->
      case Map.get(reasons, m.data["actionId"], nil) do
        reason when is_bitstring(reason) -> Message.failed(m, reason)
        _ -> m
      end
    end)
  end
end
