defmodule ProcaWeb.Resolvers.Campaign do
  import Ecto.Query
  import Ecto.Changeset
  alias Proca.Repo
  alias Proca.{Campaign,ActionPage,Staffer,Org}
  import Proca.Staffer.Permission
  alias ProcaWeb.Helper

  def list(_, %{id: id}, _) do
    cl = list_query()
    |> where([x], x.id == ^id)
    |> Proca.Repo.all

    {:ok, cl}
  end

  def list(_, %{name: name}, _) do
    cl = list_query()
    |> where([x], x.name == ^name)
    |> Proca.Repo.all

    {:ok, cl}
  end

  def list(_, %{title: title}, _) do
    cl = list_query()
    |> where([x], like(x.title, ^title))
    |> Proca.Repo.all

    {:ok, cl}
  end

  def list(_, _, _) do
    cl = Proca.Repo.all list_query()
    {:ok, cl}
  end

  defp list_query() do
    from(x in Proca.Campaign, preload: [:org])
  end

  def stats(campaign, _a, _c) do
    {supporters, at_cts} = Proca.Server.Stats.stats(campaign.id)
    {:ok,
     %{
       supporter_count: supporters,
       action_count: at_cts |> Enum.map(fn {at, ct} -> %{action_type: at, count: ct} end)
     }
    }
  end

  def declare(_, attrs = %{org_name: org_name, action_pages: pages}, %{context: %{user: user}}) do
    with %Org{} = org <- Org.get_by_name(org_name),
         %Staffer{} = staffer <- Staffer.for_user_in_org(user, org.id),
         true <- can?(staffer, :use_api)
      do
      result = Repo.transaction(fn ->
        campaign = upsert_campaign(org, attrs)
        Enum.each(pages, fn page ->
          upsert_action_page(org, campaign, page)
        end)
        campaign
      end)

      case result do
        {:ok, _} = r -> r
        {:error, invalid} -> {:error, Helper.format_errors(invalid)}
      end

      else
        _ -> {:error, "Access forbidden"}
    end
  end

  def upsert_campaign(org, attrs) do
    campaign = Campaign.upsert(org, attrs)

    if not campaign.valid? do
      Repo.rollback(campaign)
    end

    if campaign.data.id do
      Repo.update! campaign
    else
      Repo.insert! campaign
    end
  end

  def upsert_action_page(org, campaign, attrs) do
    ap = ActionPage.upsert(org, campaign, attrs)
    
    if not ap.valid? do
      Repo.rollback(ap)
    end
    
    if ap.data.id do
      Repo.update!(ap)
    else
      Repo.insert(ap)
    end
  end
end
