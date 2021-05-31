defmodule ProcaWeb.Schema.ServiceTypes do
  @moduledoc """
  API for Services
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.Authorized

  object :service_mutations do 
    field :stripe_create_payment_intent, type: non_null(:json) do 
      arg :action_page_id, non_null(:integer)
      arg :input, non_null(:stripe_payment_intent_input)

      resolve(&Resolvers.Service.stripe_create_payment_intent/3)
    end

    field :stripe_create_subscription, type: non_null(:json) do 
      arg :action_page_id, non_null(:integer)
      arg :input, non_null(:stripe_subscription_input)

      resolve(&Resolvers.Service.stripe_create_subscription/3)
    end
  end

  input_object :stripe_payment_intent_input do
    field :amount, non_null(:float)
    field :currency, non_null(:string)
    field :payment_method_types, list_of(non_null(:string))
  end

  input_object :stripe_subscription_input do
    field :amount, non_null(:float)
    field :currency, non_null(:string)
    field :frequency_unit, non_null(:donation_frequency_unit)
    # field :payment_method_types, list_of(non_null(:string))
  end
end 

