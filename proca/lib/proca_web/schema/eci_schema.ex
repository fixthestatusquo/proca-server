defmodule ProcaWeb.Schema.EciSchema do
  @moduledoc """
  An alternative API schema (replaces ProcaWeb.Schema) used in ECI build.
  """
  use Absinthe.Schema
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.ReportError
  import ProcaWeb.Resolvers.AuthNotation

  import_types(Absinthe.Type.Custom)

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.ConfirmTypes)
  import_types(ProcaWeb.Schema.CampaignTypes)
  import_types(ProcaWeb.Schema.ActionPageTypes)
  import_types(ProcaWeb.Schema.ActionTypes)
  import_types(ProcaWeb.Schema.ServiceTypes)
  import_types(ProcaWeb.Schema.OrgTypes)
  import_types(ProcaWeb.Schema.UserTypes)
  import_types(ProcaWeb.Schema.SubscriptionTypes)
  import_types(ProcaWeb.Schema.TargetTypes)

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

      load(:action_page, by: [:id, :name, :url], preload: [[campaign: :org], :org])
      resolve(fn _, _, %{context: %{action_page: ap}} -> {:ok, ap} end)

      if ReportError.enabled?(), do: middleware(ReportError)
    end
  end

  mutation do
    @desc "Adds an action with contact data"
    field :add_action_contact, type: non_null(:contact_reference) do
      middleware(Resolvers.IncludeExtensions)
      middleware(Resolvers.Captcha, defer: true)

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
      if ReportError.enabled?(), do: middleware(ReportError)
    end
  end

  def middleware(middleware, _field, %{identifier: type})
      when type in [:query, :mutation] do
    middleware ++ [ProcaWeb.Resolvers.NormalizeError]
  end

  def middleware(middleware, _field, _object) do
    middleware
  end

  def plugins do
    [MyAppWeb.Schema.Middleware.AuthorizedIntrospection | Absinthe.Plugin.defaults()]
  end
end
