defmodule ProcaWeb.Resolvers.Service do
  alias Proca.ActionPage
  alias Proca.Service

  def stripe_create_payment_intent(
        _parent,
        params = %{action_page_id: ap_id, input: input},
        context
      ) do
    with ap = %ActionPage{} <- ActionPage.find(ap_id),
         stripe = %Service{} <- Service.get_one_for_org(:stripe, ap.org) do
      pi = input

      meta =
        payment_intent_metadata(ap)
        |> put_referer(context)
        |> put_contact_ref(params)

      case Service.Stripe.create_payment_intent(stripe, pi, meta) do
        {:ok, result} -> {:ok, result}
        {:error, %Stripe.Error{} = e} -> Service.Stripe.error_to_graphql(e)
      end
    else
      nil -> {:error, "Action Page not found or does not support Stripe"}
    end
  end

  def stripe_create_subscription(
        _parent,
        params = %{action_page_id: ap_id, input: input},
        context
      ) do
    with ap = %ActionPage{} <- ActionPage.find(ap_id),
         stripe = %Service{} <- Service.get_one_for_org(:stripe, ap.org) do
      sbscr = input

      meta =
        payment_intent_metadata(ap)
        |> put_referer(context)
        |> put_contact_ref(params)

      case Service.Stripe.create_subscription(stripe, sbscr, meta) do
        {:ok, result} -> {:ok, result}
        {:error, %Stripe.Error{} = e} -> Service.Stripe.error_to_graphql(e)
      end
    else
      nil -> {:error, "Action Page not found or does not support Stripe"}
    end
  end

  def stripe_create_raw(_parent, params = %{ action_page_id: ap_id }, _ctx) do 
    with ap = %ActionPage{} <- ActionPage.find(ap_id),
         stripe = %Service{} <- Service.get_one_for_org(:stripe, ap.org) do

      case assemble_stripe_objects(params, stripe) do 
        {:ok, object} -> {:ok, object}
        {:error, e} -> Service.Stripe.error_to_graphql(e)
      end
    else
      nil -> {:error, "Action Page not found or does not support Stripe"}
    end
  end

  def assemble_stripe_objects(%{payment_intent: pi}, stripe) do 
      Service.Stripe.create_payment_intent_raw(pi, stripe)
  end

  def assemble_stripe_objects(params = %{customer: customer, subscription: sbscr}, stripe) do 
    case Service.Stripe.create_customer_raw(customer, stripe) do 
      {:ok , %{id: id}} -> 
        Map.delete(params, :customer)
        |> Map.put(:subscription, Map.put(sbscr, :customer, id))
        |> assemble_stripe_objects(stripe)
      e -> e
    end
  end

  def assemble_stripe_objects(params = %{price: price, subscription: sbscr}, stripe) do 
    case Service.Stripe.create_price_raw(price, stripe) do 
      {:ok , %{id: id}} -> 
        Map.delete(params, :price)
        |> Map.put(:subscription, Map.put(sbscr, :items, [ %{ price: id } ]))
        |> assemble_stripe_objects(stripe)
      e -> e
    end
  end

  def assemble_stripe_objects(%{price: price}, stripe) do 
      Service.Stripe.create_price_raw(price, stripe)
  end

  def assemble_stripe_objects(%{customer: customer}, stripe) do 
      Service.Stripe.create_customer_raw(customer, stripe)
  end


  def assemble_stripe_objects(%{subscription: sbscr}, stripe) do 
      Service.Stripe.create_subscription_raw(sbscr, stripe)
  end

  def assemble_stripe_objects(%{}, _stripe) do 
    {:error, "Provide Stripe objects to create"}
  end



  defp payment_intent_metadata(%ActionPage{
         name: name,
         id: id,
         campaign: %{name: campaign_name}
       }),
       do: %{
         "actionPageName" => name,
         "actionPageId" => id,
         "campaignName" => campaign_name
       }

  defp put_referer(map, %{headers: %{referer: referer}}), do: Map.put(map, "referer", referer)
  defp put_referer(map, _ctx), do: map

  defp put_contact_ref(map, %{contact_ref: ref}), do: Map.put(map, "contactRef", ref)
  defp put_contact_ref(map, _meta), do: map
end

