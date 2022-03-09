defmodule ProcaWeb.Schema.TargetTypes do
  @moduledoc """
  Schema decleration for Target and TargetEmail types
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  import ProcaWeb.Resolvers.AuthNotation

  input_object :target_email_input do
    field :email, non_null(:string)
  end

  object :target_email do
    field :email, non_null(:string)
    field :email_status, non_null(:email_status)
  end

  input_object :target_input do
    field :name, :string
    field :area, :string, default_value: ""
    field :external_id, non_null(:string)
    field :fields, :json, default_value: %{}
    field :emails, list_of(non_null(:target_email_input))
  end

  interface :target do
    field :id, non_null(:string)
    field :name, non_null(:string)
    field :external_id, non_null(:string)
    field :area, :string, default_value: ""
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

    field :emails, non_null(list_of(:target_email))
  end

  object :target_mutations do
    field :upsert_targets, type: non_null(list_of(:private_target)) do
      arg(:targets, non_null(list_of(non_null(:target_input))))
      arg(:campaign_id, non_null(:integer))
      arg(:replace, :boolean)

      load(:campaign, by: [id: :campaign_id])
      determine_auth(for: :campaign)
      allow([:change_campaign_settings])

      resolve(&Resolvers.Target.upsert_targets/3)
    end
  end

  object :target_queries do
    # XXX perhaps better to access via campaign.targets
    # field :targets, non_null(list_of(:target)) do
    #   arg(:campaign_id, non_null(:integer))

    #   resolve(&Resolvers.Target.list/3)
    # end
  end
end
