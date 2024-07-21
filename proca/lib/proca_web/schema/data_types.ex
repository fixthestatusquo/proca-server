defmodule ProcaWeb.Schema.DataTypes do
  @moduledoc """
  Defines custom types used in API, and how to serialize/parse them
  """
  use Absinthe.Schema.Notation

  import Logger

  scalar :json do
    parse(fn
      %{value: value} when is_bitstring(value) ->
        case Jason.decode(value) do
          {:ok, object} when is_map(object) ->
            {:ok, object}

          x ->
            error(why: "error while decoding json input", input: value, msg: x)
            :error
        end

      _ ->
        :error
    end)

    serialize(fn object ->
      case Jason.encode(object) do
        {:ok, json} -> json
        _ -> :error
      end
    end)
  end

  enum :contact_schema do
    value(:basic)
    value(:popular_initiative)
    value(:eci)
    value(:it_ci)
  end

  enum :donation_schema do
    value(:stripe_payment_intent)
  end

  enum :donation_frequency_unit do
    value(:one_off)
    value(:weekly)
    value(:monthly)
    value(:daily)
  end

  enum :status do
    value(:success, description: "Operation completed succesfully")
    value(:confirming, description: "Operation awaiting confirmation")
    value(:noop, description: "Operation had no effect (already done)")
  end

  enum :action_page_status do
    value(:standby,
      description:
        "This action page is ready to receive first action or is stalled for over 1 year"
    )

    value(:active, description: "This action page received actions lately")
    value(:stalled, description: "This action page did not receive actions lately")
  end

  enum :email_status do
    value(:none, description: "An unused email")

    value(:double_opt_in, description: "The user has received a DOI on this email and accepted it")

    value(:bounce, description: "This email was used and bounced")
    value(:blocked, description: "This email was used and blocked")
    value(:spam, description: "This email was used and marked spam")
    value(:unsub, description: "This email was used and user unsubscribed")
    value(:inactive, description: "This email was disabled and should not be contacted")
    value(:active, description: "This email was contacted before")
  end

  enum :queue do
    value(:email_supporter, description: "Queue of thank you email sender worker")
    value(:custom_supporter_confirm, description: "a custom queue of action that needs DOI")
    value(:custom_action_confirm, description: "a custom queue of action that needs moderation")
    value(:custom_action_deliver, description: "a custom queue of actions to sync to CRM")
    value(:sqs, description: "Queue of SQS sync worker")
    value(:webhook, description: "Queue of webhook sync worker")
  end

  enum :campaign_status do
    value(:live)
    value(:closed)
    value(:ignored)
  end

  enum :outdated_targets do
    value(:keep, description: "Keep outdated targets")
    value(:disable, description: "Disable emails for outdated targets")

    value(:delete,
      description: "Delete outdated targets (only possible for targets without any action)"
    )
  end

  # XXX should this not be moved out from here?
  object :delete_result do
    field :success, non_null(:boolean)
  end
end
