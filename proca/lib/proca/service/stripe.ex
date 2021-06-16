defmodule Proca.Service.Stripe do
  import Ecto.Changeset
  alias Proca.Service
  alias Proca.Action.Donation

  def create_payment_intent(
        service,
        params = %{
          amount: amount,
          currency: currency
        },
        metadata
      )
      when is_integer(amount) and is_bitstring(currency) do
    
    case validate_params(params) do
      {:ok, input} ->
        intent_params =
          %{
            amount: input.amount,
            currency: String.downcase(input.currency)
          }
          |> add_if_given(params, :payment_method_types)
          |> add_metadata(metadata)

        do_create_payment_intent(intent_params, service)

      {:error, _} = e -> e
    end
  end

  def validate_params(params) do 
    input = cast(%Donation{}, params, [:amount, :currency])
    |> Donation.validate_amount(:amount)
    |> Donation.validate_currency(:currency)

    if input.valid? do 
      {:ok, apply_changes(input)}
    else 
      {:error, input}
    end
  end

  def do_create_payment_intent(params, %Service{name: :stripe, password: api_key}) do 
    Stripe.PaymentIntent.create(params, api_key: api_key)
  end

  def do_create_customer(params, %Service{name: :stripe, password: api_key}) do 
    Stripe.Customer.create(params, api_key: api_key)
  end

  def do_create_price(params, %Service{name: :stripe, password: api_key}) do 
    Stripe.Price.create(params, api_key: api_key)
  end

  def do_create_subscription(params, %Service{name: :stripe, password: api_key}) do 
    Stripe.Subscription.create(params, api_key: api_key)
  end

  def create_subscription(
    service,
    %{ 
      amount: amount, 
      currency: currency,
      frequency_unit: unit 
    } = params,
    metadata
  ) 
  when is_integer(amount) and is_bitstring(currency)
  do 
    case validate_params(params) do 
      {:error, _} = e -> e
      {:ok, input} ->
        price_param = %{
          currency: input.currency,
          unit_amount: input.amount,
          recurring: %{
            interval: to_interval(unit)
            },
            product_data: %{
              name: "Donation"
            } 
          }


        with {:ok, customer} <- do_create_customer(customer(metadata), service),
             {:ok, price} <- do_create_price(price_param, service)   # warning because of product_data -> not expected in stripe library
        do

          %{
            customer: customer.id,
            items: [ %{ price: price.id } ],
            payment_behavior: "default_incomplete",
            expand: ["latest_invoice.payment_intent", "customer"]
          } 
          |> add_metadata(metadata)
          |> do_create_subscription(service)
        else
          {:error, e} -> {:error, e}
        end
    end
  end

  defp customer(%{"contactRef" => ref}) when not is_nil(ref) do 
    %{metadata: %{"contactRef" => ref} }
  end

  defp customer(_ref), do: %{}


  # hmm nothing similar in standard library...
  defp add_if_given(map, params, key) do
    case Map.get(params, key) do
      nil -> map
      value -> Map.put(map, key, value)
    end
  end

  defp add_metadata(map, metadata) when is_nil(metadata) or map_size(metadata) == 0, do: map
  defp add_metadata(map, metadata), do: Map.put(map, :metadata, metadata)

  defp to_interval(:weekly), do: "week"
  defp to_interval(:monthly), do: "month"

  def error_to_graphql(%Stripe.Error{
        message: message,
        code: code_atom,
        extra: info
      }) do
    {:error,
     [
       %{
         message: message,
         extensions: %{
             code: Atom.to_string(code_atom)
           }
           |> Map.merge(info)
       }
     ]}
  end
end


require Protocol

Protocol.derive(Jason.Encoder, Stripe.PaymentIntent)
Protocol.derive(Jason.Encoder, Stripe.Customer)
Protocol.derive(Jason.Encoder, Stripe.Price)
Protocol.derive(Jason.Encoder, Stripe.Subscription)
Protocol.derive(Jason.Encoder, Stripe.SubscriptionItem)
Protocol.derive(Jason.Encoder, Stripe.List)
Protocol.derive(Jason.Encoder, Stripe.LineItem)
Protocol.derive(Jason.Encoder, Stripe.Invoice)
Protocol.derive(Jason.Encoder, Stripe.Plan)
