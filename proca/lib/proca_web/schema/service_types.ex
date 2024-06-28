defmodule ProcaWeb.Schema.ServiceTypes do
  @moduledoc """
  API for Services
  """

  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  import ProcaWeb.Resolvers.AuthNotation

  object :service_mutations do
    @desc """
    Insert or update a service for an org, using id to to update a particular one
    """
    field :upsert_service, type: non_null(:service) do
      @desc "Owner org"
      arg(:org_name, non_null(:string))
      @desc "Id to select service to be updated"
      arg(:id, :integer)
      @desc "Content of service"
      arg(:input, non_null(:service_input))

      load(:org, by: [name: :org_name])
      determine_auth(for: :org)
      allow([:change_org_services])

      resolve(&Resolvers.Service.upsert_service/3)
    end

    @desc """
    Stripe API - add a stripe payment intent, when donating to the action page specified by id
    """
    field :add_stripe_payment_intent, type: non_null(:json) do
      @desc "Donating to this page"
      arg(:action_page_id, non_null(:integer))
      @desc "payment intent content"
      arg(:input, non_null(:stripe_payment_intent_input))
      @desc "Contact reference of donating supporter"
      arg(:contact_ref, :id)
      @desc "Use test stripe api keys"
      arg(:testing, :boolean)

      load(:action_page, by: [id: :action_page_id], preload: [:org, :campaign])
      resolve(&Resolvers.Service.add_stripe_payment_intent/3)
    end

    @desc """
    Stripe API - add a stripe subscription, when donating to the action page specified by id
    """
    field :add_stripe_subscription, type: non_null(:json) do
      @desc "Donating to this page"
      arg(:action_page_id, non_null(:integer))
      @desc "subscription intent content"
      arg(:input, non_null(:stripe_subscription_input))
      @desc "Contact reference of donating supporter"
      arg(:contact_ref, :id)
      @desc "Use test stripe api keys"
      arg(:testing, :boolean)

      load(:action_page, by: [id: :action_page_id], preload: [:org, :campaign])
      resolve(&Resolvers.Service.add_stripe_subscription/3)
    end

    #  payment intent, create customer, create subscription
    @desc """
    Create stripe object using Stripe key associated with action page owning org.
    Pass any of paymentIntent, subscription, customer, price json params to be sent as-is to Stripe API. The result is a JSON returned by Stripe API or a GraphQL Error object.
    If you provide customer along payment intent or subscription, it will be first created, then their id will be added to params for the payment intent or subscription, so you can pack 2 Stripe API calls into one. You can do the same with price object in case of a subscription.
    """
    field :add_stripe_object, type: non_null(:json) do
      arg(:action_page_id, non_null(:integer))

      @desc "Parameters for Stripe Payment Intent creation"
      arg(:payment_intent, :json)
      @desc "Parameters for Stripe Subscription creation"
      arg(:subscription, :json)
      @desc "Parameters for Stripe Customer creation"
      arg(:customer, :json)
      @desc "Parameters for Stripe Price creation"
      arg(:price, :json)
      @desc "Use test stripe api keys"
      arg(:testing, :boolean)

      load(:action_page, by: [id: :action_page_id], preload: [:org, :campaign])
      resolve(&Resolvers.Service.add_stripe_object/3)
    end
  end

  input_object :stripe_payment_intent_input do
    @desc "Amount of payment"
    field :amount, non_null(:integer)
    @desc "Currency ofo payment"
    field :currency, non_null(:string)
    @desc "Stripe payment method type"
    field :payment_method_types, list_of(non_null(:string))
  end

  input_object :stripe_subscription_input do
    @desc "Amount of payment"
    field :amount, non_null(:integer)
    @desc "Currency ofo payment"
    field :currency, non_null(:string)
    @desc "how often is recurrent payment made?"
    field :frequency_unit, non_null(:donation_frequency_unit)
    # field :payment_method_types, list_of(non_null(:string))
  end

  enum :service_name do
    value(:ses, description: "AWS SES to send emails")
    value(:sqs, description: "AWS SQS to process messages")
    value(:mailjet, description: "Mailjet to send emails")
    value(:smtp, description: "SMTP to send emails")
    value(:wordpress, description: "Wordpress HTTP API")
    value(:stripe, description: "Stripe to process donations")
    value(:test_stripe, description: "Stripe test account to test donations")
    value(:webhook, description: "HTTP POST webhook")
    # inherit from instance
    value(:system, description: "Use a service that instance org is using")
    value(:supabase, description: "Supabase to store files")
  end

  object :service do
    @desc "Id"
    field :id, non_null(:integer)
    @desc "Service name (type)"
    field :name, non_null(:service_name)

    @desc """
    Hostname of service, but can be used as any "container" of the service. For AWS, contains a region.
    """
    field :host, :string

    @desc """
    User, Account id, client id, whatever your API has
    """
    field :user, :string

    @desc """
    A sub-selector of a resource. Can be url path, but can be something like AWS bucket name
    """
    field :path, :string
  end

  input_object :service_input do
    @desc "Service name (type)"
    field :name, non_null(:service_name)

    @desc """
    Hostname of service, but can be used as any "container" of the service. For AWS, contains a region.
    """
    field :host, :string

    @desc """
    User, Account id, client id, whatever your API has
    """
    field :user, :string

    @desc """
    Password, key, secret or whatever your API has as secret credential
    """
    field :password, :string

    @desc """
    A sub-selector of a resource. Can be url path, but can be something like AWS bucket name
    """
    field :path, :string
  end
end
