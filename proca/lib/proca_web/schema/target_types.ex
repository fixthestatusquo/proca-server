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
  end

  input_object :target_input do
    field :name, non_null(:string)
    field :area, :string, default_value: ""
    field :external_id, non_null(:string)
    field :fields, :json, default_value: %{}
    field :emails, non_null(list_of(:target_email_input))
  end

  object :target do
    field :id, non_null(:string)
    field :name, non_null(:string)
    field :area, :string, default_value: ""
    field :fields, :json, default_value: %{}
    field :emails, non_null(list_of(:target_email))
  end

  object :target_mutations do
    field :upsert_targets, type: non_null(list_of(:target)) do
      arg(:targets, non_null(list_of(:target_input)))
      arg(:campaign_id, non_null(:integer))

      load(:campaign, by: [id: :campaign_id])
      determine_auth(for: :campaign)
      allow([:manage_campaigns])

      resolve(&Resolvers.Target.upsert_targets/3)
    end
  end

  object :target_queries do
    field :targets, non_null(list_of(:target)) do
      arg(:campaign_id, non_null(:integer))

      resolve(&Resolvers.Target.list/3)
    end
  end
end
