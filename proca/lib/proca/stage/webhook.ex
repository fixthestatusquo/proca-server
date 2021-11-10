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


  def start_for?(org = %{confirm_processing: true}) do
    webhook = Service.one(org: org, name: :webhook)
    not is_nil webhook
  end

  def start_for?(_), do: false


  def start_link(org = %Org{id: org_id}) do
    Broadway.start_link(__MODULE__,
      name: String.to_atom(Atom.to_string(__MODULE__) <> ".#{org_id}"),
      producer: [
        module: Proca.Pipes.Topology.broadway_producer(org, "event"),
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
        ],
      ],
      context: %{
        org: org,
        service: Service.one(org: org, name: :webhook)
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
      {:ok, event} -> Message.update_data(fn _ -> event end)

      # ignore garbled message
      {:error, reason} ->
        ignore message, reason
     end
  end

  @impl true
  def handle_batch(:default, messages, _,
    %{org: org, service: webhook}) do

    for msg <- messages do
      payload = Jason.encode!(msg.data)
      case Webhook.send(webhook, payload) do
        {:ok, _code} -> msg
        {:ok, _code, _ret} -> msg
        {:error, reason} -> Message.failed(msg, reason)
      end
    end
  end

end
