defmodule ProcaWeb.Resolvers.Org do
  # import Ecto.Query
  import Ecto.Changeset
  import Ecto.Query

  alias Proca.{ActionPage,Campaign,Contact,Consent,Supporter,Source}
  alias Proca.{Org,Staffer,PublicKey}

  alias Proca.Repo
  alias ProcaWeb.Helper
  import Proca.Staffer.Permission


  def find(_, %{name: name}, %{context: %{user: user}}) when not is_nil(user) do
    with %Org{} = org <- Org.get_by_name(name),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
           true <- can?(s, :use_api)
      do
      {:ok, org}
    else
      _ -> {:error, "Access forbidden"}
    end
  end

  def find(_, %{name: _name}, _ctx) do
    {:error, "You need to authorize with Basic auth"}
  end

  def campaign(org, %{id: camp_id}, _) do
    c = from(c in Campaign,
      left_join: ap in ActionPage,
      on: c.id == ap.campaign_id,
      where: c.id == ^camp_id and (ap.org_id == ^org.id or c.org_id == ^org.id ))
    |> distinct(true)
    |> Repo.one

    {:ok, c}
  end

  def campaigns(org, _, _) do
    cl = from(c in Campaign,
      left_join: ap in ActionPage,
      on: c.id == ap.campaign_id,
      where: ap.org_id == ^org.id or c.org_id == ^org.id)
    |> distinct(true)
    |> Repo.all

    {:ok, cl}
  end

  def action_pages(org, _, _) do
    c = from(ap in ActionPage, where: ap.org_id == ^org.id)
    |> Repo.all

    {:ok, c}
  end


  defp org_signatures(org) do
    from(s in Supporter,
      join: c in Contact, on: c.supporter_id == s.id,
      join: g in Consent, on: g.supporter_id == s.id,
      join: pk in PublicKey, on: pk.id == c.public_key_id,
      join: ap in ActionPage, on: s.action_page_id == ap.id,
      order_by: [asc: s.id],
      where: pk.org_id == ^org.id
    )

  end

  defp org_signatures_for_campaign(org, campaign_id) do
    org_signatures(org)
    |> where([ap], ap.campaign_id == ^campaign_id)
  end

  defp signatures_list(query, limit_sigs) do
    my_pk = Proca.Server.Encrypt.get_keys()

    q = case limit_sigs do
          nil -> query
          lim -> query |> limit(^lim)
        end

    q = select(q, [s, x, c, g, pk, ap], %{
          id: s.id,
          created: s.inserted_at,
          nonce: c.encrypted_nonce,
          contact: c.encrypted,
          action_page_id: ap.id,
          campaign_id: ap.campaign_id,
          opt_in: g.communication
               })

    sigs = Repo.all q

    {
      :ok,
      %{
        public_key: PublicKey.base_encode(my_pk.public),
        list: Enum.map(sigs, fn s -> %{s |
                                       nonce: Contact.base_encode(s.nonce),
                                       contact: Contact.base_encode(s.contact)
                                      }
        end)
      }
    }
  end


  def signatures(org, arg = %{campaign_id: campaign_id, start: id}, _) do
    org_signatures_for_campaign(org, campaign_id)
    |> where([c], c.id >= ^id)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{campaign_id: campaign_id, after: dt}, _) do
    org_signatures_for_campaign(org, campaign_id)
    |> where([s], s.inserted_at >= ^dt)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{campaign_id: campaign_id}, _) do
    org_signatures_for_campaign(org, campaign_id)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{start: id}, _) do
    org_signatures(org)
    |> where([c], c.id >= ^id)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{after: dt}, _) do
    org_signatures(org)
    |> where([s], s.inserted_at >= ^dt)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg, _) do
    org_signatures(org)
    |> signatures_list(Map.get(arg, :limit))
  end
end

