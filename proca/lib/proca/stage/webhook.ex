defmodule Proca.Stage.Webhook do
  @moduledoc """
  Processing "stage" that sends events to webhook.

  This is only started for the webhook owned by the org, so it is not run for
  org that uses instance org webhook

  """
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Org, ActionPage, Action, Supporter, Service}
  alias Proca.Service.Webhook
  alias Proca.Repo
  import Ecto.Query
  import Logger
  import Proca.Stage.Support, only: [ignore: 1, ignore: 2, supporter_link: 3]

  @doc "Get selected webhook service"
  def get_service(org = %{event_backend_id: id}) do
    Service.one(org: org, id: id, name: :webhook)
  end

  def get_service(_), do: nil

  def start_for?(org = %{confirm_processing: true}) do
    webhook = get_service(org)
    not is_nil(webhook)
  end

  def start_for?(org = %{event_processing: true}) do
    webhook = get_service(org)
    not is_nil(webhook)
  end

  def start_for?(_), do: false

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
        org: org
      }
    )
  end

  @doc """
  Not all actions generate thank you emails.

  1. Email and template backend must be configured for the org (Org, AP, )
  2. ActionPage's email template must be set [present in JSON]. (XXX Or fallback to org one?)
  """

  @impl true
  def handle_message(_, message = %Message{data: data}, _) do
    case JSON.decode(data) do
      {:ok, event} ->
        Message.update_data(message, fn _ -> event end)

      # ignore garbled message
      {:error, reason} ->
        ignore(message, reason)
    end
  end

  @impl true
  def handle_batch(:default, messages, _, %{org: org}) do
    webhook = get_service(org)

    for msg <- messages do
      payload = Jason.encode!(msg.data)

      case Webhook.push(webhook, payload) do
        {:ok, 200} ->
          msg

        {:ok, 200, _ret} ->
          msg

        {:ok, 404} ->
          error("Webhook returned 404 Not found: #{webhook.host}")
          Message.failed(msg, "Not found")

        {:error, reason} ->
          error("Webhook failed: #{inspect(reason)}: #{webhook.host}")
          Message.failed(msg, reason)
      end
    end
  end
end
