defmodule ProcaWeb.Schema.DataTypes do
  @moduledoc """
  Defines custom types used in API, and how to serialize/parse them
  """
  use Absinthe.Schema.Notation

  import Logger

  scalar :json do
    parse(fn %{value: value} when is_bitstring(value) ->
        case Jason.decode(value) do
          {:ok, object} ->
            {:ok, object}

          x ->
            error [why: "error while decoding json input", input: value, msg: x]
            :error
        end
      _ -> :error
    end)

    serialize(fn object ->
      case Jason.encode(object) do
        {:ok, json} -> json
        _ -> :error
      end
    end)
  end

  enum :contact_schema do
    value :basic
    value :popular_initiative
    value :eci
    value :it_ci
  end

  enum :donation_schema do 
    value :stripe_payment_intent 
  end

  enum :donation_frequency_unit do 
    value :one_off 
    value :weekly 
    value :monthly
  end 

  enum :status do
    value :success, description: "Operation completed succesfully"
    value :confirming, description: "Operation awaiting confirmation"
  end

  # XXX should this not be moved out from here?
  object :delete_result do
    field :success, non_null(:boolean)
  end
end
