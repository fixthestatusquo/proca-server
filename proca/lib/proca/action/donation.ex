defmodule Proca.Action.Donation do
  use Ecto.Schema
  alias Proca.Action.Donation
  import Ecto.Changeset

  schema "donations" do
    field :schema, DonationSchema, default: nil
    field :payload, :map, default: %{}
    field :amount, :decimal
    field :currency, :string, default: "EUR"
    field :frequency_unit, DonationFrequencyUnit, default: :one_off

    belongs_to :action, Proca.Action

    timestamps()
  end

  @doc false
  def changeset(donation, attrs) do
    donation
    |> cast(attrs, [:schema, :payload, :amount, :currency, :frequency_unit])
    |> extract_amount()
    |> extract_currency()
    |> validate_required([:payload, :amount, :currency])
    |> validate_format(:currency, ~r/^[A-Z]{3}$/)
    |> validate_change(:amount, fn :amount, amount -> 
      if Decimal.gt?(amount, 0), do: [], else: [amount: "must be positive"]
    end)
  end

  def changeset(attrs) when is_map(attrs) do 
    changeset(%Donation{}, attrs)
  end

  def extract_amount(%Ecto.Changeset{changes: %{payload: payload}} = ch) do 
    schema = get_field(ch, :schema)
    case amount_in_schema(schema, payload) do 
      :error -> add_error(ch, :payload, "payload does not contain amount, schema: #{schema}")
      x when is_nil(x) -> ch
      amount -> put_change(ch, :amount, amount)
    end
  end

  def extract_currency(%Ecto.Changeset{changes: %{payload: payload}} = ch) do 
    schema = get_field(ch, :schema)
    case currency_in_schema(schema, payload) do 
      :error -> add_error(ch, :payload, "payload does not contain currency, schema: #{schema}")
      x when is_nil(x) -> ch
      amount -> put_change(ch, :currency, amount)
    end
  end

  def amount_in_schema(:stripe_payment_intent, payload) do 
    case payload do 
      %{"amount" => cents} when is_integer(cents) -> 
        Decimal.new(cents) |> Decimal.div(100)
      _ -> :error
    end
  end

  def amount_in_schema(_opaque_schema, _payload), do: nil 

  def currency_in_schema(:stripe_payment_intent, payload) do 
    case payload do 
      %{"currency" => currency} -> String.upcase(currency)
      _ -> :error
    end
  end

  def currency_in_schema(_other, _payload), do: nil
end
