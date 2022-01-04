defmodule Proca.Stage.Event do
  alias Proca.{Confirm, Org, Supporter}
  alias Proca.Pipes.Connection
  import Proca.Stage.Support, only: [camel_case_keys: 1]

  def emit(:confirm_created, %Confirm{} = confirm, org_id) when is_number(org_id) do
    routing_key = "confirm_created." <> Atom.to_string(confirm.operation)

    meta = %{event_type: "confirm_created", operation: confirm.operation}

    data =
      Confirm.notify_fields(confirm)
      |> put_meta(meta)
      |> camel_case_keys()

    Connection.publish(exchange_for(org_id), routing_key, data)
  end

  def emit(:supporter_updated, %Supporter{} = supporter, org_id) when is_number(org_id) do
    alias Proca.Stage.MessageV2
    alias Proca.Action

    routing_key = "supporter_updated"
    meta = %{event_type: "supporter_updated"}

    contact_by_org_id = fn
      %{org_id: ^org_id} -> true
      _ -> false
    end

    contact = Enum.find(supporter.contacts, contact_by_org_id)

    data =
      %{
        contact: MessageV2.contact_data(supporter, contact),
        privacy: MessageV2.contact_privacy(%Action{with_consent: true}, contact)
      }
      |> put_meta(meta)
      |> camel_case_keys()

    Connection.publish(exchange_for(org_id), routing_key, data)
  end

  def emit(:campaign_updated, campaign, org_id) do
    routing_key = "campaign_updated"
    meta = %{event_type: "campaign_updated"}

    campaign = campaign |> Proca.Repo.preload([:org])

    data =
      campaign
      |> Map.from_struct()
      |> Map.take([:id, :name, :external_id, :title, :config, :contact_schema])
      |> Map.merge(%{
        campaign_id: campaign.id,
        org_id: campaign.org.id,
        org: %{
          name: campaign.org.name,
          title: campaign.org.title
        }
      })
      |> put_meta(meta)
      |> camel_case_keys()

    Connection.publish(exchange_for(org_id), routing_key, data)
  end

  defp exchange_for(org_id) when is_number(org_id) do
    Proca.Pipes.Topology.xn(%Org{id: org_id}, "event")
  end

  defp put_meta(payload, meta) do
    payload
    |> Map.merge(meta)
    |> Map.put(:schema, "proca:event:2")
  end
end
