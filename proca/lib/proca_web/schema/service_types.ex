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
      arg :input, non_null(:payment_intent_input)

      resolve(&Resolvers.Service.stripe_create_payment_intent/3)
    end
  end

  input_object :payment_intent_input do
      field :amount, non_null(:float)
      field :currency, non_null(:string)
      field :payment_method_types, list_of(non_null(:string))
  end
end 

