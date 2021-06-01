defmodule Proca.Service.Stripe do
  import Ecto.Changeset
  alias Proca.Service

  @spec create_payment_intent(any, any) :: none
  def create_payment_intent(
        %Service{name: :stripe, password: api_key},
        %{
          amount: amount,
          currency: currency
        } = intent_args
      )
      when is_float(amount) and is_bitstring(currency) do
    to_send =
      Map.merge(intent_args, %{amount: to_cents(amount), currency: String.downcase(currency)})

    Stripe.PaymentIntent.create(to_send, api_key: api_key)
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
         extensions:
           %{
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
