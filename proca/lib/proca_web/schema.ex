defmodule ProcaWeb.Schema do
  @moduledoc """
  Main API schema. See schema/ for details.

  Note about date time types: 
  - be conservative in what you do (return data using :native_datetime)
  - be liberal about what you expect from others (accept :datetime possibly with a timezone)
  (is this principle even a progressive one?)
  """
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)

  import_types(ProcaWeb.Schema.DataTypes)
  import_types(ProcaWeb.Schema.CampaignTypes)
  import_types(ProcaWeb.Schema.ActionTypes)
  import_types(ProcaWeb.Schema.UserTypes)
  import_types(ProcaWeb.Schema.OrgTypes)
  import_types(ProcaWeb.Schema.SubscriptionTypes)
  import_types(ProcaWeb.Schema.ServiceTypes)
  import_types(ProcaWeb.Schema.ConfirmTypes)

  query do
    import_fields(:campaign_queries)
    import_fields(:action_queries)
    import_fields(:user_queries)
    import_fields(:org_queries)
  end

  mutation do
    import_fields(:campaign_mutations)
    import_fields(:action_mutations)
    import_fields(:user_mutations)
    import_fields(:org_mutations)
    import_fields(:service_mutations)
    import_fields(:confirm_mutations)
  end

  subscription do
    import_fields(:updates)
  end
end
