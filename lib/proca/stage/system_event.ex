defmodule Proca.Stage.SystemEvent do
  @moduledoc """
  Builds and emits action-like messages for organisational lifecycle events
  (`org.add`, `user.add`, `campaign.join`, `user.join`, `user.update`) to the
  event exchange with `system.<entity>.<verb>` routing keys. These get forwarded
  to the instance org's queues for CRM integration.

  Messages use the `proca:action:2` schema so CRM consumers can process them
  similarly to supporter action events, with the "contact" being the
  campaigner/user rather than a supporter.
  """

  alias Proca.Org
  alias Proca.Users.User
  alias Proca.Stage.MessageV2
  alias Proca.Pipes.{Connection, Topology}
  alias Proca.Repo
  import Logger
  import Proca.Stage.Support, only: [user_data: 1]

  def emit(data, event_type, org_id) do
    routing_key = "system." <> Atom.to_string(event_type)
    exchange = Topology.xn(%Org{id: org_id}, "event")

    result =
      data
      |> Map.put("schema", "proca:action:2")
      |> Map.put("stage", "system")
      |> Map.put("eventType", Atom.to_string(event_type))
      |> Connection.publish(exchange, routing_key)

    case result do
      :ok ->
        :ok

      {:error, reason} ->
        warning(
          "SystemEvent #{event_type} publish failed: #{inspect(reason)} exchange=#{exchange}"
        )

        {:error, reason}
    end
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

  def emit_campaign_join(user, org, campaign, action_page) do
    campaign_join_data(user, org, campaign, action_page)
    |> emit(:"campaign.join", campaign.org_id)
  end

  @doc "An org joins a campaign."
  def campaign_join_data(user, org, campaign, action_page) do
    action_page = Repo.preload(action_page, [:org, :campaign])

    system_action(
      actor: user,
      contact: user_contact_data(user),
      action_type: "campaign.join",
      custom_fields: %{},
      org: org,
      campaign: campaign,
      action_page: action_page
    )
  end

  def emit_org_add(user, org) do
    org_add_data(user, org)
    |> emit(:"org.add", instance_org_id())
  end

  @doc "An org (and its owner) is added."
  def org_add_data(user, org) do
    system_action(
      actor: user,
      contact: user_contact_data(user),
      action_type: "org.add",
      custom_fields: %{},
      org: org
    )
  end

  def emit_user_add(user) do
    user_add_data(user)
    |> emit(:"user.add", instance_org_id())
  end

  @doc "A user registers."
  def user_add_data(user) do
    system_action(
      actor: user,
      contact: user_contact_data(user),
      action_type: "user.add",
      custom_fields: %{}
    )
  end

  @doc """
  A user joins an org (staffer membership added). `contact` is the user being
  added, `user` the actor, `org`/`orgId` the org joined; the role goes in
  `action.customFields`.
  """
  def emit_user_join(actor, user, org, role) do
    user_join_data(actor, user, org, role)
    |> emit(:"user.join", org.id)
  end

  def user_join_data(actor, user, org, role) do
    system_action(
      actor: actor,
      contact: user_contact_data(user),
      action_type: "user.join",
      custom_fields: %{"role" => Atom.to_string(role)},
      org: org
    )
  end

  @doc """
  A user changed. `customFields` is the role for a role change, or the changed
  profile field names (no values) for a profile change. `org` is the membership
  org, or nil for an instance-level profile change.
  """
  def emit_user_update(actor, user, org, custom_fields) do
    user_update_data(actor, user, org, custom_fields)
    |> emit(:"user.update", org_id(org))
  end

  def user_update_data(actor, user, org, custom_fields) do
    system_action(
      actor: actor,
      contact: user_contact_data(user),
      action_type: "user.update",
      custom_fields: custom_fields,
      org: org
    )
  end

  @doc "A user changes their email (self-service confirmation)."
  def emit_user_email_update(actor, user) do
    user_email_update_data(actor, user)
    |> emit(:"user.update", instance_org_id())
  end

  def user_email_update_data(actor, user) do
    system_action(
      actor: actor,
      contact: user_contact_data(user),
      action_type: "updateEmail",
      custom_fields: %{}
    )
  end

  defp system_action(opts) do
    org = opts[:org]
    campaign = opts[:campaign]
    action_page = opts[:action_page]

    %{
      "contact" => opts[:contact],
      "user" => user_data(opts[:actor]),
      "personalInfo" => nil,
      "privacy" => %{},
      "tracking" => %{},
      "org" => org && %{"name" => org.name, "title" => org.title},
      "orgId" => org && org.id,
      "campaign" => campaign && MessageV2.campaign_data(campaign),
      "campaignId" => campaign && campaign.id,
      "actionPage" => action_page && MessageV2.action_page_data(action_page),
      "actionPageId" => action_page && action_page.id,
      "action" => %{
        "actionType" => opts[:action_type],
        "customFields" => opts[:custom_fields],
        "createdAt" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "testing" => false
      },
      "actionId" => nil
    }
  end

  defp org_id(nil), do: instance_org_id()
  defp org_id(%Org{id: id}), do: id

  defp instance_org_id, do: Proca.Server.Instance.org().id
end
