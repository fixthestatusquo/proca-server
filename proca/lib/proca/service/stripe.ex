defmodule Proca.Service.Stripe do
  import Ecto.Changeset
  alias Proca.Service

  def create_payment_intent(
        %Service{name: :stripe, password: api_key},
        params = %{
          amount: amount,
          currency: currency
        }
      )
      when is_float(amount) and is_bitstring(currency) do
    intent_args =
      %{
        amount: to_cents(amount),
        currency: String.upcase(currency)
      }
      |> add_if_given(params, :payment_method_types)
      |> add_if_given(params, :metadata)

    Stripe.PaymentIntent.create(intent_args, api_key: api_key)
  end

  # hmm nothing similar in standard library...
  defp add_if_given(map, params, key) do
    case Map.get(params, key) do
      nil -> map
      value -> Map.put(map, key, value)
    end
  end

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
Protocol.derive(Jason.Encoder, Stripe.List)
