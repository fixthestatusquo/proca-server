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

      meta = payment_intent_metadata(ap)
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
      meta = payment_intent_metadata(ap)
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
