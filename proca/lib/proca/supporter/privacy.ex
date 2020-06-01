defmodule Proca.Supporter.Privacy do
  @moduledoc """
  This module specifies how the supporter presonal data is stored and share between orgs.

  ## Personal data in Proca

  Personal data is decoupled from actions in following way:

  Each action is identitfied by Action record and can reference a supporter

  Supporter records an individual taking action. Can be identified differently
  based on collected personal data, for instance, by email passport hash. If
  supporter signs up many times, many supporter records will be created, but
  with same fingerprint. This supporter will be just counted once per campaign.
  Supporter has many contacts.

  Contact stores personal data. It can store encrypted, or unencrypted payload.
  When encrypted, there is a separate Contact record for each receiving orgs'
  PublicKey. If unencrypted, there is only one Contact record. It's not possible
  to encrypt contact data for one org, but not for the other, in case when one
  org is missing active PublicKey, they will not receive the data (otherwise
  encryption for one destination would be defeated by cleartext contact payload
  for another).

  Contact data can be distributed to:
  - action page org
  - campaign org
  - partner org (this can be any other org)

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

  alias Proca.PublicKey
  alias Proca.Repo

  @doc """
  privacy - for now, a simple privacy map is: %{ opt_in: :boolean, lead_opt_in: :boolean }. Exactly what we have in the API
  """
  @spec recipients(Proca.ActionPage, map()) :: [Proca.Org]
  def recipients(action_page, privacy) do
    action_page = Repo.preload(action_page, [:org, campaign: :org])
    partner_delivery = action_page.delivery
    lead_delivery = not partner_delivery or action_page.campaign.force_delivery

    partner_communication = privacy.opt_in
    lead_communication = privacy.lead_opt_in

    partner_org =
      case partner_delivery or partner_communication do
        true -> [action_page.org]
        false -> []
      end

    lead_org =
      case lead_delivery or lead_communication do
        true -> [action_page.campaign.org]
        false -> []
      end

    Enum.uniq_by(partner_org ++ lead_org, fn o -> o.id end)
  end

  @doc """
  Is contact data encrypted in this case? If any of the data recipients encrypts data, data will only be encrypted to such recipients. Returns {true, [list of keys]}

  If none is encrypting data, contact will be stored plaintext. Returns false.
  """
  @spec is_encrypted([Proca.Org]) :: false | {true, [Proca.PublicKey]}
  def is_encrypted(data_recipients) do
    active_keys =
      data_recipients
      |> Enum.map(fn org -> PublicKey.active_keys_for(org) end)
      |> List.flatten()

    case active_keys do
      [] -> false
      keys -> {true, keys}
    end
  end
end
