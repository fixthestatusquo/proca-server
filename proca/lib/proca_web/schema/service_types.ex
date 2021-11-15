defmodule ProcaWeb.Schema.ServiceTypes do
  @moduledoc """
  API for Services
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.Authorized

  object :service_mutations do 
    field :upsert_service, type: non_null(:service) do 
      middleware Authorized,
        access: [:org, by: [name: :org_name]],
        can?: [:change_org_services]

      arg :org_name, non_null(:string)
      arg :id, :integer
      arg :input, non_null(:service_input)

      resolve(&Resolvers.Service.upsert_service/3)
    end

    field :add_stripe_payment_intent, type: non_null(:json) do 
      arg :action_page_id, non_null(:integer)
      arg :input, non_null(:stripe_payment_intent_input)
      arg :contact_ref, :id

      resolve(&Resolvers.Service.add_stripe_payment_intent/3)
    end

    field :add_stripe_subscription, type: non_null(:json) do 
      arg :action_page_id, non_null(:integer)
      arg :input, non_null(:stripe_subscription_input)
      arg :contact_ref, :id

      resolve(&Resolvers.Service.add_stripe_subscription/3)
    end

#  payment intent, create customer, create subscription
    @desc """
    Create stripe object using Stripe key associated with action page owning org.
    Pass any of paymentIntent, subscription, customer, price json params to be sent as-is to Stripe API. The result is a JSON returned by Stripe API or a GraphQL Error object.
    If you provide customer along payment intent or subscription, it will be first created, then their id will be added to params for the payment intent or subscription, so you can pack 2 Stripe API calls into one. You can do the same with price object in case of a subscription.
    """
    field :add_stripe_object, type: non_null(:json) do 
      arg :action_page_id, non_null(:integer)

      @desc "Parameters for Stripe Payment Intent creation"
      arg :payment_intent, :json
      @desc "Parameters for Stripe Subscription creation"
      arg :subscription, :json
      @desc "Parameters for Stripe Customer creation"
      arg :customer, :json 
      @desc "Parameters for Stripe Price creation"
      arg :price, :json

      resolve(&Resolvers.Service.add_stripe_object/3)
    end
  end

  input_object :stripe_payment_intent_input do
    field :amount, non_null(:integer)
    field :currency, non_null(:string)
    field :payment_method_types, list_of(non_null(:string))
  end

  input_object :stripe_subscription_input do
    field :amount, non_null(:integer)
    field :currency, non_null(:string)
    field :frequency_unit, non_null(:donation_frequency_unit)
    # field :payment_method_types, list_of(non_null(:string))
  end

  enum :service_name do 
    value :ses 
    value :sqs 
    value :mailjet
    value :wordpress
    value :stripe
    value :webhook
  end 

  object :service do 
    field :id, non_null(:integer)
    field :name, non_null(:service_name)
    field :host, :string
    field :user, :string
    field :path, :string
  end

  input_object :service_input do 
    field :name, non_null(:service_name)
    field :host, :string
    field :user, :string
    field :password, :string
    field :path, :string
  end
end 

