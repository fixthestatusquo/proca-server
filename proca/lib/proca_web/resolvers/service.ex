defmodule ProcaWeb.Resolvers.Service do
  alias Proca.ActionPage
  alias Proca.Service

  def stripe_create_payment_intent(
        _parent,
        _params = %{action_page_id: ap_id, input: input},
        context
      ) do
    with ap = %ActionPage{} <- ActionPage.find(ap_id),
         stripe = %Service{} <- Service.get_one_for_org(:stripe, ap.org) do
      pi = input
      |> Map.put(:metadata,
        payment_intent_metadata(ap)
        |> put_referer(context))

      case Service.Stripe.create_payment_intent(stripe, pi) |> IO.inspect(label: "pi") do
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
end
