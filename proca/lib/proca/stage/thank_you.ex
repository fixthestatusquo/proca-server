defmodule Proca.Stage.ThankYou do
  @moduledoc """
  Processing "stage" that sends thank you emails
  """
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Org, ActionPage, Action}
  alias Proca.Repo
  import Ecto.Query
  import Logger
  
  alias Proca.Service.{EmailBackend, EmailRecipient, EmailTemplate}

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module:
          {BroadwayRabbitMQ.Producer,
           queue: "system.email.thankyou",
           connection: Proca.Server.Plumbing.connection_url(),
           qos: [
             prefetch_count: 10
           ]},
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ],
      batchers: [
        transactional: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 1
        ],
        noop: [
          batch_size: 1,
          concurrency: 1
        ]
      ]
    )
  end

  @doc """
  Not all actions generate thank you emails.

  1. Email and template backend must be configured for the org (Org, AP, )
  2. ActionPage's action_type must be first in journey. Always send if no journey set [In DB]
  3. ActionPage's email template must be set [present in JSON]. (XXX Or fallback to org one?)
  """

  @impl true
  def handle_message(_, message = %Message{data: data}, _) do
    case JSON.decode(data) do
      {:ok,
       %{"actionPageId" => action_page_id, "actionId" => action_id} = action} ->
        if send_thank_you?(action_page_id, action_id) do
          message
          |> Message.update_data(fn _ -> action end)
          |> Message.put_batch_key(action_page_id)
          |> Message.put_batcher(:transactional)
        else
          message
          |> Message.put_batcher(:noop)
        end

      {:error, reason} ->
        Message.failed(message, reason)
    end
  end

  @impl true
  def handle_batch(:transactional, messages, %BatchInfo{batch_key: ap_id}, _) do
    ap =
      from(ap in ActionPage,
        where: ap.id == ^ap_id,
        preload: [org: [[email_backend: :org], :template_backend]]
      )
      |> Repo.one()

    recipients = Enum.map(messages, fn m -> EmailRecipient.from_action_data(m.data) end)

    info("Sending thank you email to these recipients: #{inspect(recipients)}")
    tmpl = %EmailTemplate{ref: ap.thank_you_template_ref}

    try do
      EmailBackend.deliver(recipients, ap.org, tmpl)
      messages
    rescue
      x in EmailBackend.NotDeliverd ->
        error("Failed to send email batch #{x.message}")
        Enum.map(messages, &Message.failed(&1, x.message))
    end
  end

  @impl true
  def handle_batch(:noop, messages, _, _) do
    messages
    |> Message.ack_immediately()
  end

  defp send_thank_you?(action_page_id, action_id) do
    from(a in Action,
      join: ap in ActionPage,
      on: a.action_page_id == ap.id,
      join: o in Org,
      on: o.id == ap.org_id,
      where:
        a.id == ^action_id and
        a.with_consent and
        ap.id == ^action_page_id and
          not is_nil(ap.thank_you_template_ref) and
          not is_nil(o.email_backend_id) and
          not is_nil(o.template_backend_id) and
          not is_nil(o.email_from)
    )
    |> Repo.one() != nil
  end
end
