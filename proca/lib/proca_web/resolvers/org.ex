defmodule ProcaWeb.Resolvers.Org do
  # import Ecto.Query
  import Ecto.Changeset
  import Ecto.Query

  alias Proca.{ActionPage, Campaign, Contact, Supporter, Source}
  alias Proca.{Org, Staffer, PublicKey}

  alias Proca.Repo
  alias ProcaWeb.Helper
  import Proca.Staffer.Permission


  def get_by_name(_, %{name: name}, %{context: %{user: user}})  do
    with %Org{} = org <- Org.get_by_name(name, [[campaigns: :org], :action_pages]),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
           true <- can?(s, :use_api)
      do
      {:ok, org}
    else
      _ -> {:error, "Access forbidden"}
    end
  end

  def campaign_by_id(org, %{id: camp_id}, _) do
    c = Campaign.select_by_org(org)
    |> where([c], c.id == ^camp_id)
    |> Repo.one

    case c do
      nil -> {:error, "not_found"}
      c -> {:ok, c}
    end
  end

  def campaigns(org, _, _) do
    cl = Campaign.select_by_org(org)
    |> preload([c], [:org])
    |> Repo.all

    {:ok, cl}
  end

  def action_pages(org, _, _) do
    c = Ecto.assoc(org, :action_pages)
    |> preload([ap], [:org])
    |> Repo.all
    |> Enum.map(&ActionPage.stringify_config(&1))

    {:ok, c}
  end

  def action_page(%{id: org_id}, params, _) do
    case  ProcaWeb.Resolvers.ActionPage.find(nil, params, nil) do
      {:ok, %ActionPage{org_id: ^org_id}} = ret -> ret
      {:ok, %ActionPage{}} -> {:error, %{
                                  message: "Action page not found",
                                  extensions: %{code: "not_found"}
                               }}
      {:error, x} -> {:error, x}
    end
  end


  defp org_signatures(org) do
    from(s in Supporter,
      join: c in Contact, on: s.id == c.supporter_id,
      join: ap in ActionPage, on: s.action_page_id == ap.id,
      order_by: [asc: s.id],
      where: c.org_id == ^org.id
    )
  end

  defp org_signatures_for_campaign(org, campaign_id) do
    org_signatures(org)
    |> where([s, c, ap], ap.campaign_id == ^campaign_id)
  end

  defp signatures_list(query, limit_sigs) do
    my_pk = Proca.Server.Encrypt.get_keys()

    q = case limit_sigs do
          nil -> query
          lim -> query |> limit(^lim)
        end

    q = select(q, [s, c, ap], %{
          id: s.id,
          created: s.inserted_at,
          nonce: c.crypto_nonce,
          contact: c.payload,
          action_page_id: ap.id,
          campaign_id: ap.campaign_id,
          opt_in: c.communication_consent
               })

    sigs = Repo.all q

    {
      :ok,
      %{
        public_key: PublicKey.base_encode(my_pk.public),
        list: Enum.map(sigs, fn s -> %{s |
                                       nonce: case s.nonce do
                                                nonce when is_nil(nonce) -> nil
                                                nonce -> Contact.base_encode(s.nonce)
                                              end,
                                       contact: case s.nonce do
                                                  nonce when is_nil(nonce) -> s.contact
                                                  nonce -> Contact.base_encode(s.contact)
                                                end
                                      }
        end)
      }
    }
  end


  def signatures(org, arg = %{campaign_id: campaign_id, start: id}, _) do
    org_signatures_for_campaign(org, campaign_id)
    |> where([s, c, ap], c.id >= ^id)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{campaign_id: campaign_id, after: dt}, _) do
    org_signatures_for_campaign(org, campaign_id)
    |> where([s, c, ap], s.inserted_at >= ^dt)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{campaign_id: campaign_id}, _) do
    org_signatures_for_campaign(org, campaign_id)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{start: id}, _) do
    org_signatures(org)
    |> where([s, c, ap], c.id >= ^id)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg = %{after: dt}, _) do
    org_signatures(org)
    |> where([s, c, ap], s.inserted_at >= ^dt)
    |> signatures_list(Map.get(arg, :limit))
  end

  def signatures(org, arg, _) do
    org_signatures(org)
    |> signatures_list(Map.get(arg, :limit))
  end

  def org_personal_data(org, _args, _ctx) do
    {
      :ok,
      %{
        contact_schema: org.contact_schema,
        email_opt_in: org.email_opt_in,
        email_opt_in_template: org.email_opt_in_template
      }
    }
  end

  def update_org(_p, %{name: name} = attrs, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(name),
         %Staffer{} = s <- Staffer.for_user_in_org(user, org.id),
           true <- can?(s, :use_api)
      do
      Org.changeset(org, attrs)
      |> Repo.update()
      else
        _ -> {:error, "Access forbidden"}
    end
  end

  def list_keys(%{id: org_id}, _, %{context: %{user: user}}) do
    with %Staffer{} = s <- Staffer.for_user_in_org(user, org_id),
         true <- can?(s, [:use_api, :export_contacts])
      do
      {
        :ok,
        from(pk in PublicKey, where: pk.org_id == ^org_id,
          select: %{id: pk.id, name: pk.name, public: pk.public, expired_at: pk.expired_at})
          |> Repo.all
          |> Enum.map(&Map.put(&1, :public, PublicKey.base_encode(&1.public)))
      }
      else
        _ -> {:error, "Access forbidden"}
    end
  end
end

