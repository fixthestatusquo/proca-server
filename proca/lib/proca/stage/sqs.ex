defmodule Proca.Stage.SQS do
  @moduledoc """
  Processing "stage" that sends data to SQS
  """
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Org, Service}
  require Logger

  def start_for?(org = %Org{}) do
    case Proca.Repo.preload(org, [:push_backend, :event_backend]) do
      %{push_backend: %{name: :sqs}} -> true
      %{event_backend: %{name: :sqs}} -> true
      _ -> false
    end
  end

  def start_link(org = %Org{id: org_id}) do
    Broadway.start_link(__MODULE__,
      name: String.to_atom(Atom.to_string(__MODULE__) <> ".#{org_id}"),
      producer: [
        module: Proca.Pipes.Topology.broadway_producer(org, "sqs"),
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
      ],
      context: %{
        org: Proca.Repo.preload(org, [:push_backend, :event_backend])
      }
    )
  end

  @impl true
  def handle_message(_, message = %Message{data: data}, _) do
    case JSON.decode(data) do
      {:ok, %{"orgId" => org_id, "schema" => schema} = action} ->
        message
        |> Message.put_data(action)
        |> Message.put_batch_key({org_id, content_type(schema)})
        |> Message.put_batcher(:sqs)

      {:error, reason} ->
        Message.failed(message, inspect(reason))
    end
  end

  defp content_type(schema) do
    case schema do
      "proca:event" <> _ -> :event
      "proca:action" <> _ -> :action
    end
  end

  @impl true
  def handle_batch(_sqs, msgs, %BatchInfo{batch_key: {org_id, content_type}}, %{org: org}) do
    service =
      case content_type do
        :event -> org.event_backend
        :action -> org.push_backend
      end

    if service != nil do
      actions =
        msgs
        |> Enum.map(& &1.data)
        |> Enum.map(&to_message/1)

      sent =
        ExAws.SQS.send_message_batch(service.path, actions)
        |> Service.aws_request(service)

      case sent do
        {:ok, status} ->
          mark_partial_failures(msgs, status)

        {:error, {:http_error, http_code, %{message: message}}} ->
          Logger.error("SQS forward: #{http_code} #{message}")
          Enum.map(msgs, &Message.failed(&1, message))

        _ ->
          Enum.map(msgs, &Message.failed(&1, "Cannot call SQS.SendMessageBatch"))
      end
    else
      Enum.map(
        msgs,
        &Message.failed(&1, "SQS service not found for #{org_id} and #{content_type}")
      )
    end
  end

  def to_message(body) do
    {:ok, payload} = JSON.encode(body)
    [id: body["actionId"], message_body: payload, message_attributes: to_message_attributes(body)]
  end

  # NOTE: these attributes are same in Schema V1 and V2
  def to_message_attributes(body) do
    [
      %{name: "Schema", data_type: :string, value: body["schema"]},
      %{name: "Stage", data_type: :string, value: body["stage"]},
      %{name: "CampaignName", data_type: :string, value: body["campaign"]["name"]},
      %{name: "ActionType", data_type: :string, value: body["action"]["actionType"]}
    ]
  end

  def mark_partial_failures(messages, %{
        "SendMessageBatchResponse" => %{"SendMessageBatchResult" => %{"Failed" => nil}}
      }) do
    messages
  end

  def mark_partial_failures(messages, %{
        "SendMessageBatchResponse" => %{"SendMessageBatchResult" => %{"Failed" => fails}}
      }) do
    reasons =
      Enum.reduce(fails, %{}, fn %{"pId" => id, "Message" => msg}, acc ->
        Map.put(acc, String.to_integer(id), msg)
      end)

    messages
    |> Enum.map(fn m ->
      case Map.get(reasons, m.data["actionId"], nil) do
        reason when is_bitstring(reason) -> Message.failed(m, reason)
        _ -> m
      end
    end)
  end
end
