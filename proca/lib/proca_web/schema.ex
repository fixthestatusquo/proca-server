defmodule ProcaWeb.Schema do
  use Absinthe.Schema

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.CampaignTypes)
  import_types(ProcaWeb.Schema.ActionTypes)
  import_types(ProcaWeb.Schema.OrgTypes)
  import_types(ProcaWeb.Schema.SubscriptionTypes)

  query do
    import_fields :campaign_queries
    import_fields :action_queries
    import_fields :org_queries
  end

  mutation do
    import_fields :campaign_mutations
    import_fields :action_mutations
    import_fields :org_mutations
  end

  subscription do
    import_fields :updates
  end
end
