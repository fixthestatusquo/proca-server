defmodule ProcaWeb.Resolvers.Service do
  alias Proca.ActionPage
  alias Proca.Service
  alias ProcaWeb.Helper
  alias ProcaWeb.Error
  import Proca.Repo

  def upsert_service(_p, %{id: id, input: attrs}, %{context: %{org: org}}) do
    result =
      case Service.one([id: id, org: org] ++ [:latest]) do
        nil ->
          {:error, Helper.msg_ext("Cannot find service with #{id}", :not_found)}

        srv ->
          Service.changeset(srv, attrs)
          |> Proca.Validations.validate_not_changed(:name)
          |> update()
      end

    case result do
      {:ok, service} -> {:ok, service}
      {:error, %Error{}} = e -> e
      {:error, error} -> {:error, Helper.format_errors(error)}
    end
  end

  def upsert_service(_p, %{input: attrs = %{name: name}}, %{context: %{org: org}}) do
    result =
      case Service.one([name: name, org: org] ++ [:latest]) do
        nil -> Service.build_for_org(attrs, org, name)
        srv -> Service.changeset(srv, attrs)
      end
      |> insert_or_update()

    case result do
      {:ok, service} -> {:ok, service}
      {:error, error} -> {:error, Helper.format_errors(error)}
    end
  end

  defp stripe_service(org, testing) do
    name = if testing, do: :test_stripe, else: :stripe
    Service.one([name: name, org: org] ++ [:latest])
  end

  def add_stripe_payment_intent(
        _parent,
        params = %{input: input},
        context = %{context: %{action_page: ap}}
      ) do
    with stripe = %Service{} <- stripe_service(ap.org, Map.get(params, :testing, false)) do
      pi = input

      meta =
        payment_intent_metadata(ap)
        |> put_referer(context)
        |> put_contact_ref(params)

      case Service.Stripe.create_payment_intent(stripe, pi, meta) do
        {:ok, result} -> {:ok, result}
        {:error, %Stripe.Error{} = e} -> Service.Stripe.error_to_graphql(e)
        {:error, %Ecto.Changeset{} = ch} -> {:error, ProcaWeb.Helper.format_errors(ch)}
      end
    else
      nil -> {:error, "Action Page does not support Stripe"}
    end
  end

  def add_stripe_subscription(
        _parent,
        params = %{input: input},
        context = %{context: %{action_page: ap}}
      ) do
    with stripe = %Service{} <- stripe_service(ap.org, Map.get(params, :testing, false)) do
      sbscr = input

      meta =
        payment_intent_metadata(ap)
        |> put_referer(context)
        |> put_contact_ref(params)

      case Service.Stripe.create_subscription(stripe, sbscr, meta) do
        # XXX warning because stripe lib type incomplete
        {:ok, result} -> {:ok, result}
        {:error, %Stripe.Error{} = e} -> Service.Stripe.error_to_graphql(e)
        {:error, %Ecto.Changeset{} = ch} -> {:error, ProcaWeb.Helper.format_errors(ch)}
      end
    else
      nil -> {:error, "Action Page does not support Stripe"}
    end
  end

  def add_stripe_object(
        _parent,
        params,
        %{context: %{action_page: ap}}
      ) do
    with stripe = %Service{} <- stripe_service(ap.org, Map.get(params, :testing, false)) do
      case assemble_stripe_objects(params, stripe) do
        {:ok, object} -> {:ok, object}
        {:error, e} -> Service.Stripe.error_to_graphql(e)
      end
    else
      nil -> {:error, "Action Page does not support Stripe"}
    end
  end

  def assemble_stripe_objects(params = %{customer: customer, payment_intent: pi}, stripe) do
    case Service.Stripe.do_create_customer(customer, stripe) do
      {:ok, %{id: id}} ->
        Map.delete(params, :customer)
        |> Map.put(:payment_intent, Map.put(pi, :customer, id))
        |> assemble_stripe_objects(stripe)

      e ->
        e
    end
  end

  def assemble_stripe_objects(params = %{customer: customer, subscription: sbscr}, stripe) do
    case Service.Stripe.do_create_customer(customer, stripe) do
      {:ok, %{id: id}} ->
        Map.delete(params, :customer)
        |> Map.put(:subscription, Map.put(sbscr, :customer, id))
        |> assemble_stripe_objects(stripe)

      e ->
        e
    end
  end

  def assemble_stripe_objects(params = %{price: price, subscription: sbscr}, stripe) do
    case Service.Stripe.do_create_price(price, stripe) do
      {:ok, %{id: id}} ->
        Map.delete(params, :price)
        |> Map.put(:subscription, Map.put(sbscr, :items, [%{price: id}]))
        |> assemble_stripe_objects(stripe)

      e ->
        e
    end
  end

  def assemble_stripe_objects(%{payment_intent: pi}, stripe) do
    Service.Stripe.do_create_payment_intent(pi, stripe)
  end

  def assemble_stripe_objects(%{price: price}, stripe) do
    Service.Stripe.do_create_price(price, stripe)
  end

  def assemble_stripe_objects(%{customer: customer}, stripe) do
    Service.Stripe.do_create_customer(customer, stripe)
  end

  def assemble_stripe_objects(%{subscription: sbscr}, stripe) do
    Service.Stripe.do_create_subscription(sbscr, stripe)
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
