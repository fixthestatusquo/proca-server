defmodule Proca.Stage.Event do
  @moduledoc """
  Define JSON format for events in proca system.

  These events are mostly CRUD operations that happened on different records.

  If and only if the org has `custom_event_deliver` or `event_backend` set, a special message with
  schema "proca.event.2" will be injected into deliver queue, along action data.

  If instance org has events enabled, it gets events from ALL orgs.

  The event backend enables you to send events to SQS or webhook, and the
  `custom_event_deliver` means events are stored in custom delivery queue you
  can read.

  """
  alias Proca.{Action, Confirm, Org, Supporter}
  alias Proca.Pipes.Connection
  import Proca.Stage.Support, only: [camel_case_keys: 2, to_iso8601: 1]

  @doc """
  Routing key for the event message is two-element topic routing key for confirms (because they have subtype), and one element key for CRUD events.

  Examples:
  - confirm_created.add_staffer - for new add_staffer confirm XXX remove!
  - supporter.email_status_changed
  - system.campaign_updated - for any campaign update
  """
  def routing_key(event, %Confirm{operation: op}) do
    Atom.to_string(event) <> "." <> Atom.to_string(op)
  end

  def routing_key(event, %Supporter{}) do
    "supporter." <> Atom.to_string(event)
  end

  def routing_key(event, _record) do
    "system." <> Atom.to_string(event)
  end

  def metadata(event, record) do
    ts =
      case record do
        %{updated_at: t} -> t
        _ -> DateTime.utc_now()
      end

    %{
      schema: "proca:event:2",
      event_type: event,
      timestamp: to_iso8601(ts)
    }
  end

  def emit(event, record, org_id, opts \\ []) when is_number(org_id) do
    rkey = routing_key(event, record)
    meta = metadata(event, record)

    meta
    |> put_data(event, record, opts ++ [org_id: org_id])
    |> camel_case_keys(ignore: :config)
    |> Connection.publish(exchange_for(org_id), rkey)
  end

  def put_data(data, :confirm_created, %Confirm{} = confirm, _opts) do
    data
    |> Map.put(:confirm, Confirm.notify_fields(confirm))
  end

  def put_data(data, :email_status, %Supporter{} = supporter, opts) do
    alias Proca.Stage.MessageV1
    alias Proca.Stage.MessageV2

    action = Action.get_by_id(opts[:id])

    # Find Supporters contact data belonging to that org_id
    org_id = opts[:org_id]

    contact_by_org_id = fn
      %{org_id: ^org_id} -> true
      _ -> false
    end

    contact = Enum.find(supporter.contacts, contact_by_org_id)

    contact = Proca.Repo.preload(contact, [:public_key, :sign_key])

    supporter_data = %{
      contact: MessageV2.contact_data(supporter, contact),
      privacy: MessageV2.contact_privacy(supporter, contact),
      personal_info: MessageV2.personal_info_data(contact)
    }

    action_data = %{
      action_type: action.action_type,
      custom_fields: action.fields,
      created_at: action.inserted_at |> to_iso8601(),
      testing: action.testing
    }

    data
    |> Map.put(:supporter, supporter_data)
    |> Map.put(:campaign, MessageV2.campaign_data(action.campaign))
    |> Map.put(:campaign_id, action.campaign.id)
    |> Map.put(:action_page, MessageV2.action_page_data(action.action_page))
    |> Map.put(:action_page_id, action.action_page.id)
    |> Map.put(:action_id, action.id)
    |> Map.put(:action, action_data)
    |> Map.put(:tracking, MessageV1.tracking_data(action))
  end

  def put_data(data, :campaign_updated, campaign, _opts) do
    campaign = campaign |> Proca.Repo.preload([:org])

    org_data = %{
      name: campaign.org.name,
      title: campaign.org.title
    }

    campaign_data =
      campaign
      |> Map.from_struct()
      |> Map.take([:id, :name, :external_id, :title, :config, :contact_schema])
      |> Map.put(:org, org_data)

    data
    |> Map.put(:campaign, campaign_data)
    |> Map.put(:campaign_id, campaign.id)
    |> Map.put(:org_id, campaign.org.id)
  end

  defp exchange_for(org_id) when is_number(org_id) do
    Proca.Pipes.Topology.xn(%Org{id: org_id}, "event")
  end
end
