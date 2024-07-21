defmodule Proca.Stage.Webhook do
  @moduledoc """
  Processing "stage" that sends events to webhook.

  This is only started for the webhook owned by the org, so it is not run for
  org that uses instance org webhook

  """
  use Broadway

  alias Broadway.Message
  alias Proca.Org
  alias Proca.Service.Webhook
  import Logger

  import Proca.Stage.Support,
    only: [ignore: 2, too_many_retries?: 1]

  def start_for?(org = %Org{}) do
    case Proca.Repo.preload(org, [:push_backend, :event_backend]) do
      %{push_backend: %{name: :webhook}} -> true
      %{event_backend: %{name: :webhook}} -> true
      _ -> false
    end
  end

  def start_link(org = %Org{id: org_id}) do
    Broadway.start_link(__MODULE__,
      name: String.to_atom(Atom.to_string(__MODULE__) <> ".#{org_id}"),
      producer: [
        module: Proca.Pipes.Topology.broadway_producer(org, "webhook"),
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ],
      batchers: [
        default: [
          batch_size: 10,
          batch_timeout: 10_000,
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
    if too_many_retries?(message) do
      ignore(message, "too many retries")
    else
      case JSON.decode(data) do
        {:ok, event} ->
          Message.put_data(message, event)

        # ignore garbled message
        {:error, reason} ->
          ignore(message, reason)
      end
    end
  end

  @impl true
  def handle_batch(:default, messages, _, %{org: org}) do
    for msg <- messages do
      webhook =
        case msg.data do
          %{"schema" => "proca:event" <> _} -> org.event_backend
          %{"schema" => "proca:action" <> _} -> org.push_backend
        end

      case Webhook.push(webhook, msg.data) do
        {:ok, 200} ->
          msg

        {:ok, 200, _ret} ->
          msg

        {:ok, 404} ->
          error("Webhook returned 404 Not found: #{webhook.host}")
          Message.failed(msg, "Not found")

        {:ok, code} ->
          Sentry.capture_message(
            "Webhook #{webhook.host} returned HTTP code #{code}",
            capture: :none
          )

          error("Webhook returned #{code} code: #{webhook.host}")
          Message.failed(msg, "Code #{code}")

        {:error, reason} ->
          error("Webhook failed: #{inspect(reason)}: #{webhook.host}")
          Message.failed(msg, reason)
      end
    end
  end
end
