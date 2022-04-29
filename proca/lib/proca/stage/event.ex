defmodule Proca.Stage.Event do
  @moduledoc """
  Define JSON format for events in proca system.

  These events are mostly CRUD operations that happened on different records.
  """
  alias Proca.{Confirm, Org, Supporter}
  alias Proca.Pipes.Connection
  import Proca.Stage.Support, only: [camel_case_keys: 1, to_iso8601: 1]

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

    data =
      meta
      |> put_data(event, record, opts ++ [org_id: org_id])
      |> camel_case_keys()

    Connection.publish(exchange_for(org_id), rkey, data)
  end

  def put_data(data, :confirm_created, %Confirm{} = confirm, _opts) do
    data
    |> Map.put(:confirm, Confirm.notify_fields(confirm))
  end

  def put_data(data, :email_status, %Supporter{} = supporter, opts) do
    alias Proca.Stage.MessageV2

    # Find Supporters contact data belonging to that org_id
    org_id = opts[:org_id]

    contact_by_org_id = fn
      %{org_id: ^org_id} -> true
      _ -> false
    end

    contact = Enum.find(supporter.contacts, contact_by_org_id)

    supporter_data = %{
      contact: MessageV2.contact_data(supporter, contact),
      privacy: MessageV2.contact_privacy(supporter, contact),
      personal_info: MessageV2.personal_info_data(contact)
    }

    data
    |> Map.put(:supporter, supporter_data)
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
