defmodule Proca.Stage.SystemEvent do
  @moduledoc """
  Builds and emits action-like messages for organisational lifecycle events
  (join_campaign, new_org, new_user) to the event exchange with `system.*`
  routing keys. These get forwarded to the instance org's queues for CRM
  integration.

  Messages use the `proca:action:2` schema so CRM consumers can process them
  similarly to supporter action events, with the "contact" being the
  campaigner/user rather than a supporter.
  """

  alias Proca.{Org, Campaign, ActionPage}
  alias Proca.Users.User
  alias Proca.Stage.MessageV2
  alias Proca.Stage.Support
  alias Proca.Pipes.{Connection, Topology}
  alias Proca.Repo

  def emit(data, event_type, org_id) do
    routing_key = "system." <> Atom.to_string(event_type)
    exchange = Topology.xn(%Org{id: org_id}, "event")

    data
    |> Map.put("schema", "proca:action:2")
    |> Map.put("stage", "system")
    |> Map.put("eventType", Atom.to_string(event_type))
    |> Connection.publish(exchange, routing_key)
  end

  def user_contact_data(%User{email: email}) do
    first_name =
      case email do
        nil -> nil
        e -> e |> String.split("@") |> List.first()
      end

    %{
      "firstName" => first_name,
      "email" => email,
      "contactRef" => nil,
      "dupeRank" => 0,
      "area" => nil
    }
  end

  def emit_join_campaign(user, org, campaign, action_page) do
    action_page = Repo.preload(action_page, [:org, :campaign])

    %{
      "contact" => user_contact_data(user),
      "personalInfo" => nil,
      "privacy" => %{},
      "tracking" => %{},
      "org" => %{"name" => org.name, "title" => org.title},
      "orgId" => org.id,
      "campaign" => MessageV2.campaign_data(campaign),
      "campaignId" => campaign.id,
      "actionPage" => MessageV2.action_page_data(action_page),
      "actionPageId" => action_page.id,
      "action" => %{
        "actionType" => "join_campaign",
        "customFields" => %{},
        "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "testing" => false
      },
      "actionId" => nil
    }
    |> emit(:join_campaign, campaign.org_id)
  end

  def emit_new_org(user, org) do
    instance_org_id = Proca.Server.Instance.org().id

    %{
      "contact" => user_contact_data(user),
      "personalInfo" => nil,
      "privacy" => %{},
      "tracking" => %{},
      "org" => %{"name" => org.name, "title" => org.title},
      "orgId" => org.id,
      "campaign" => nil,
      "campaignId" => nil,
      "actionPage" => nil,
      "actionPageId" => nil,
      "action" => %{
        "actionType" => "new_org",
        "customFields" => %{},
        "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "testing" => false
      },
      "actionId" => nil
    }
    |> emit(:new_org, instance_org_id)
  end

  def emit_new_user(user) do
    instance_org_id = Proca.Server.Instance.org().id

    %{
      "contact" => user_contact_data(user),
      "personalInfo" => nil,
      "privacy" => %{},
      "tracking" => %{},
      "org" => nil,
      "orgId" => nil,
      "campaign" => nil,
      "campaignId" => nil,
      "actionPage" => nil,
      "actionPageId" => nil,
      "action" => %{
        "actionType" => "new_user",
        "customFields" => %{},
        "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "testing" => false
      },
      "actionId" => nil
    }
    |> emit(:new_user, instance_org_id)
  end
end
