defmodule Proca.Supporter.Privacy do
  @moduledoc """
  This module specifies how the supporter presonal data is stored and share between orgs.

  ## Personal data in Proca

  Personal data is decoupled from actions in following way:

  Each action is identitfied by Action record and can reference a supporter

  Supporter records an individual taking action. Can be identified uniquely by a
  fingeprint, which is calculated based on current Contact Data format. For
  instance in Proca.Contact.BasicData, fingerprint is a seeded SHA256 hash of
  email. If supporter signs up many times, many supporter records will be
  created, but with same fingerprint. This supporter will be just counted once
  per campaign. Supporter has many Contact records.

  Contact stores personal data and privacy/consent information. It can store
  encrypted, or unencrypted payload. There is a separate Contact record for each
  Org receiving contact data. 

  Contact data can be distributed to:
  - Widget Org collecting data on Action Page
  - Lead Org running the campaign (if different)
  - 3rd Party Org (this can be any other org)

  When it is distributed, there is a consent associated with delivery and
  communication areas (and a scope, currently email, but could be email, sms etc).

  ### Example setups
  1. Org runs Campaign and Action page - they get contact data, with email opt in true/false
  2a. Org runs Action Page of Org' Campaign - Org gets data for delivery and email opt in, Org' nothing
  2b. Org gets data for delivery and email opt in, Org' gets data iff campaign opt in is true (otherwise )
  2c. 2b but other way round. It's (central) Org' that delivers, and Org gets data only if email opt in is true
  3. Also some extra partner org can get data

  XXX For now, lets leave out extra partner config (should they be set on action page or campaign level?)

  XXX ActionPage should have new columns:
  delivery: :boolean, defualt: true - means, action page owner delivers signatures

  XXX Campaign should have new columns:
  force_delivery: :boolean, default: false - if true, campaign owner delivers contact data even if action page owner does it already. If false, only delivers if action page does not.

  User gives consent in a privacy object. Right now they can only decide about
  communication consent, the delivery consent is implicit and they can't say for instance, that their signature should be included in action page owner delivery but not the campaign owner delivery. XXX Check if this is okay wrt GDPR.

  """

  alias Proca.Supporter.{Privacy, Consent}
  alias Proca.{ActionPage, Org, Campaign, Action}

  defstruct opt_in: false,
            lead_opt_in: false

  @default_communication_scopes ["email"]

  @doc """
  privacy - for now, a simple privacy map is: %{ opt_in: :boolean, lead_opt_in: :boolean }.
  Exactly what we have in the API.
  """
  @spec consents(%ActionPage{}, %Privacy{}) :: [%Consent{}]
  def consents(action_page = %ActionPage{}, privacy = %Privacy{}) when not is_nil(action_page) do
    action_page = Proca.Repo.preload(action_page, [:org, campaign: :org])

    is_split = action_page.campaign.org_id != action_page.org_id

    # when not splitting, collector is processor, also when it delivers
    widget_delivery = not is_split or action_page.delivery

    lead_delivery = not widget_delivery or action_page.campaign.force_delivery

    widget_communication = privacy.opt_in
    lead_communication = privacy.lead_opt_in

    collector_consent = %Consent{
      org: action_page.org,
      communication_consent: widget_communication,
      communication_scopes: @default_communication_scopes,
      delivery_consent: widget_delivery
    }

    lead_consent = %Consent{
      org: action_page.campaign.org,
      communication_consent: lead_communication,
      communication_scopes: @default_communication_scopes,
      delivery_consent: lead_delivery
    }

    if action_page.live do
      [collector_consent, lead_consent]
    else
      [collector_consent]
    end
    |> Enum.filter(fn %{delivery_consent: dc, communication_consent: cc} -> dc or cc end)
  end

  def cleartext_fields(%ActionPage{org: %Org{high_security: true}}) do
    [:area]
  end

  def cleartext_fields(_) do
    [:email, :first_name, :area]
  end

  @doc "Which supporter fields are cleared after processing"
  def transient_supporter_fields(%ActionPage{org: %Org{high_security: true}}) do
    [:email, :first_name]
  end

  def transient_supporter_fields(_) do
    [:email]
  end

  def transient_action_fields(%Action{action_type: action_type}, %ActionPage{
        campaign: %Campaign{transient_actions: afs}
      }) do
    x = action_type <> ":"

    afs
    |> Enum.filter(fn af -> String.starts_with?(af, x) end)
    |> Enum.map(fn af -> af |> String.split(":") |> Enum.at(1) end)
  end
end
