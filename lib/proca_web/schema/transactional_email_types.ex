defmodule ProcaWeb.Schema.TransactionalEmailTypes do
  @moduledoc """
  API for transactional emails (thank you, supporter confirm, ...): per role,
  whether it is on, how it is sent and which template it uses, set on an org,
  a campaign or an action page. See `Proca.TransactionalEmail`.
  """

  use Absinthe.Schema.Notation
  import ProcaWeb.Resolvers.AuthNotation
  alias ProcaWeb.Resolvers

  enum :transactional_email_role do
    value(:thank_you, description: "Thank you email to every supporter")

    value(:double_optin,
      description: "Thank you email to opt-ins only (with the double opt-in link)"
    )

    value(:supporter_confirm,
      description:
        "Asks the supporter to confirm their signature (the action is held until they do)"
    )

    value(:supporter_confirm_reminder1, description: "First reminder to confirm")
    value(:supporter_confirm_reminder2, description: "Second reminder to confirm")
    value(:duplicate, description: "Sent to supporters who sign again")
    value(:user_confirm_email, description: "Instance org only")
    value(:user_reset_password, description: "Instance org only")
    value(:add_staffer, description: "Instance org only")
    value(:add_partner, description: "Instance org only")
    value(:launch_page, description: "Instance org only")
    value(:join_campaign, description: "Instance org only")
  end

  enum :transactional_email_mechanism do
    value(:own_template, description: "Template of the org sending the email")
    value(:system_template, description: "Template of the instance org")

    value(:external_queue,
      description: "No email, the action goes to the custom queue (supporter_confirm only)"
    )
  end

  enum :transactional_email_level do
    value(:action_page)
    value(:campaign)
    value(:org)
  end

  @desc """
  A transactional email setting stored at one level. Null fields inherit
  from the next level (action page -> campaign -> org).
  """
  object :transactional_email do
    field :id, non_null(:integer)
    field :role, non_null(:transactional_email_role)

    @desc "Where this setting is stored"
    field :level, non_null(:transactional_email_level) do
      resolve(fn te, _, _ -> {:ok, Proca.TransactionalEmail.level(te)} end)
    end

    @desc "On or off, null = inherit"
    field :state, :boolean
    @desc "How the email is sent, null = inherit"
    field :mechanism, :transactional_email_mechanism
    @desc "Template name, null = inherit"
    field :template_ref, :string
    @desc "Settings for this role (e.g. reminder delay_hours), each key inherited separately"
    field :config, :json
  end

  @desc """
  Fields to set. A field left out keeps its value, null means inherit.
  """
  input_object :transactional_email_input do
    field :state, :boolean
    field :mechanism, :transactional_email_mechanism
    field :template_ref, :string
    @desc "JSON object, e.g. {\"delay_hours\": 48}"
    field :config, :json
  end

  input_object :select_transactional_email do
    field :role, :transactional_email_role
  end

  object :transactional_email_mutations do
    @desc """
    Add a transactional email setting for a role on an org, a campaign
    (campaignName) or an action page (actionPageId). The campaign or page
    must belong to the org. Fails if the role is already set there; use
    updateTransactionalEmail.
    """
    field :add_transactional_email, type: non_null(:transactional_email) do
      @desc "Org that owns the setting (and the campaign or page)"
      arg(:org_name, non_null(:string))
      @desc "Set it on this campaign of the org"
      arg(:campaign_name, :string)
      @desc "Set it on this action page of the org"
      arg(:action_page_id, :integer)
      arg(:role, non_null(:transactional_email_role))
      arg(:input, non_null(:transactional_email_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_campaign_settings])

      resolve(&Resolvers.TransactionalEmail.add/3)
    end

    @desc """
    Update a transactional email setting, picked by id, or by role on the org,
    a campaign (campaignName) or an action page (actionPageId).
    """
    field :update_transactional_email, type: non_null(:transactional_email) do
      @desc "Org that owns the setting"
      arg(:org_name, non_null(:string))
      @desc "Pick the setting by id..."
      arg(:id, :integer)
      @desc "...or by role, on the org or on campaignName / actionPageId"
      arg(:role, :transactional_email_role)
      arg(:campaign_name, :string)
      arg(:action_page_id, :integer)
      arg(:input, non_null(:transactional_email_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_campaign_settings])

      resolve(&Resolvers.TransactionalEmail.update/3)
    end

    @desc """
    Delete a transactional email setting (its level goes back to inheriting),
    picked by id, or by role on the org, a campaign or an action page.
    """
    field :delete_transactional_email, type: non_null(:status) do
      @desc "Org that owns the setting"
      arg(:org_name, non_null(:string))
      @desc "Pick the setting by id..."
      arg(:id, :integer)
      @desc "...or by role, on the org or on campaignName / actionPageId"
      arg(:role, :transactional_email_role)
      arg(:campaign_name, :string)
      arg(:action_page_id, :integer)

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_campaign_settings])

      resolve(&Resolvers.TransactionalEmail.delete/3)
    end
  end
end
