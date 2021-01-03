defmodule ProcaWeb.Schema.EciSchema do
  @moduledoc """
  An alternative API schema (replaces ProcaWeb.Schema) used in ECI build.
  """
  use Absinthe.Schema
  alias ProcaWeb.Resolvers

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.CampaignTypes)
  import_types(ProcaWeb.Schema.ActionTypes)
  import_types(ProcaWeb.Schema.OrgTypes)
  import_types(ProcaWeb.Schema.UserTypes)
  import_types(ProcaWeb.Schema.SubscriptionTypes)

  # use Absinthe.Schema.Notation

  query do
    @desc "Get action page"
    field :action_page, non_null(:public_action_page) do
      @desc "Get action page by id."
      arg(:id, :integer)
      @desc "Get action page by name the widget is displayed on"
      arg(:name, :string)
      @desc "Get action page by url the widget is displayed on (DEPRECATED, use name)"
      arg(:url, :string)

      resolve(&Resolvers.ActionPage.find/3)
    end
  end

  mutation do
    @desc "Adds an action with contact data"
    field :add_action_contact, type: non_null(:contact_reference) do
      middleware(Resolvers.IncludeExtensions)
      middleware(Resolvers.Captcha)

      arg(:action_page_id, non_null(:integer))

      @desc "Action data"
      arg(:action, non_null(:action_input))

      @desc "GDPR communication opt"
      arg(:contact, non_null(:contact_input))

      @desc "Signature action data"
      arg(:privacy, non_null(:consent_input))

      @desc "Tracking codes (UTM_*)"
      arg(:tracking, :tracking_input)

      @desc "Links to previous contact reference"
      arg(:contact_ref, :id)

      resolve(&Resolvers.Action.add_action_contact/3)
    end
  end
end
