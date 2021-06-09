defmodule Proca.Service.Stripe do
  import Ecto.Changeset
  alias Proca.Service

  def create_payment_intent(
        service,
        params = %{
          amount: amount,
          currency: currency
        },
        metadata
      )
      when is_float(amount) and is_bitstring(currency) do
    intent_params =
      %{
        amount: to_cents(amount),
        currency: String.downcase(currency)
      }
      |> add_if_given(params, :payment_method_types)
      |> add_metadata(metadata)

    do_create_payment_intent(intent_params, service)
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
    },
    metadata
  ) 
  when is_float(amount) and is_bitstring(currency)
  do 

    price_param = %{
        currency: currency,
        unit_amount: to_cents(amount),
        recurring: %{
          interval: to_interval(unit)
        },
        product_data: %{
          name: "Donation"
        } 
    }


    with {:ok, customer} <- do_create_customer(customer(metadata), service),
         {:ok, price} <- do_create_price(price_param, service)
      do

      %{
        customer: customer.id,
        items: [ %{ price: price.id } ],
        payment_behavior: "default_incomplete",
        expand: ["latest_invoice.payment_intent"]
      } 
      |> add_metadata(metadata)
      |> do_create_subscription(service)
    else
      {:error, e} -> {:error, e}
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

  defp to_cents(amount) do
    Decimal.from_float(amount) |> Decimal.mult(100) |> Decimal.to_integer()
  end

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
