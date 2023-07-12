defmodule ProcaWeb.Schema.TargetTypes do
  @moduledoc """
  Schema decleration for Target and TargetEmail types
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  import ProcaWeb.Resolvers.AuthNotation

  input_object :target_email_input do
    @desc "Email of target"
    field :email, non_null(:string)
  end

  object :target_email do
    @desc "Email of target"
    field :email, non_null(:string)
    @desc "The status of email (normal or bouncing etc)"
    field :email_status, non_null(:email_status)
    @desc "An error received when bouncing email was reported"
    field :error, :string
  end

  input_object :target_input do
    @desc "Name of target"
    field :name, :string
    @desc "unique external_id of target, used to upsert target"
    field :external_id, non_null(:string)
    @desc "Locale of this target (in which language do they read emails?)"
    field :locale, :string
    @desc "Area of the target"
    field :area, :string
    @desc "Custom fields, stringified json"
    field :fields, :json
    @desc "Email list of this target"
    field :emails, list_of(non_null(:target_email_input))
  end

  interface :target do
    field :id, non_null(:string)
    @desc "Name of target"
    field :name, non_null(:string)
    @desc "unique external_id of target, used to upsert target"
    field :external_id, non_null(:string)
    @desc "Locale of this target (in which language do they read emails?)"
    field :locale, :string
    @desc "Area of the target"
    field :area, :string, default_value: ""
    @desc "Custom fields, stringified json"
    field :fields, :json, default_value: %{}

    resolve_type(fn
      _, %{context: %{auth: auth}} ->
        if Proca.Permission.can?(auth, [:instance_owner]),
          do: :private_target,
          else: :public_target

      # XXX add check for membership of campaign group - when we add them
      # %{campaign_id: cid}, %{context: %{auth: %Auth{group: %{campaign_id: cid}}}} -> :private_target

      _, _ ->
        :public_target
    end)
  end

  object :public_target do
    interface(:target)
    import_fields(:target)
  end

  object :private_target do
    interface(:target)
    import_fields(:target)

    @desc "Email list of this target"
    field :emails, non_null(list_of(:target_email))
  end

  object :target_mutations do
    @desc """
    Upsert multiple targets at once.
    external_id is used to decide if new target record is added, or existing one is updated.
    """
    field :upsert_targets, type: non_null(list_of(:private_target)) do
      @desc "List of targets"
      arg(:targets, non_null(list_of(non_null(:target_input))))
      @desc "Id of campaign these targets are added to"
      arg(:campaign_id, non_null(:integer))
      @desc "Remove targets not existing in this upsert (if false, upsert will merge with omitted targets)"
      arg(:replace, :boolean)

      load(:campaign, by: [id: :campaign_id])
      determine_auth(for: :campaign)
      allow([:change_campaign_settings])

      resolve(&Resolvers.Target.upsert_targets/3)
    end
  end

  # object :target_queries do
  # XXX perhaps better to access via campaign.targets
  # field :targets, non_null(list_of(:target)) do
  #   arg(:campaign_id, non_null(:integer))

  #   resolve(&Resolvers.Target.list/3)
  # end
  # end
end
