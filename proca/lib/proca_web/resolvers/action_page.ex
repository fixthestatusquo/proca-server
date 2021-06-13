defmodule ProcaWeb.Resolvers.ActionPage do
  @moduledoc """
  Resolvers for action page related mutations
  """
  import Ecto.Query
  alias Proca.{ActionPage, Campaign, Org}
  alias Proca.Repo
  alias ProcaWeb.Helper
  import Ecto.Changeset


  defp by_id(query, id) do
    query |> where([x], x.id == ^id)
  end

  defp by_name(query, name) do
    query |> where([x], x.name == ^name)
  end

  defp find_one(criteria) do
    query =
      from(p in Proca.ActionPage, preload: [[campaign: :org], :org], limit: 1)
      |> criteria.()

    case Proca.Repo.one query do
      nil -> {:error, %{
                 message: "Action page not found",
                 extensions: %{code: "not_found"} } }
      ap -> {:ok, ap}
    end
  end

  def find(_, %{id: id}, _) do
    find_one(&by_id(&1, id))
  end

  def find(_, %{name: name}, _) do
    find_one(&by_name(&1, name))
  end

  def find(_, %{}, _) do
    {:error, "You must pass either id or name to query for ActionPage"}
  end

  def campaign(ap, %{}, _) do
    {
      :ok,
      Repo.preload(ap, campaign: :org).campaign
    }
  end

  def org(ap, %{}, _) do 
    {
      :ok,
      Repo.preload(ap, :org).org
    }
  end

  def update(_, %{input: attrs}, %{context: %{action_page: ap}}) do
    case ap
    |> ActionPage.changeset(attrs)
    |> Repo.update()
      do
      {:error,  chset = %Ecto.Changeset{}} -> {:error, Helper.format_errors(chset)}
      {:ok, ap} ->
        Proca.Server.Notify.action_page_updated(ap)
        {:ok, ap}
    end
  end

  def copy_from(_, %{name: name, from_name: from_name}, %{context: %{org: org}}) do
    with ap when not is_nil(ap) <- ActionPage.find(from_name),
         {:ok, new_ap} <- ActionPage.create_copy_in(org, ap, %{name: name})
    do
    Proca.Server.Notify.action_page_added(new_ap)
    {:ok, new_ap}
    else
      nil -> {:error, "ActionPage named #{from_name} not found"}
      {:error, %Ecto.Changeset{valid?: false} = ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def copy_from_campaign(_, %{name: name, from_campaign_name: camp_name}, %{context: %{org: org}}) do
    with campaign when not is_nil(campaign) <- Campaign.get_with_local_pages(camp_name),
        [ap | _] <- campaign.action_pages,
        {:ok, new_ap} <- ActionPage.create_copy_in(org, ap, %{name: name})
    do
    Proca.Server.Notify.action_page_added(new_ap)
    {:ok, new_ap}
    else
      nil -> {:error, "Campaign named #{camp_name} not found"}
      [] -> {:error, "Campaign #{camp_name} does not have action pages"}
      {:error, %Ecto.Changeset{valid?: false} = ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def launch_page(_, %{name: name}, %{context: %{staffer: st}}) do 
    with ap = %ActionPage{} <- ActionPage.find(name),
        org <- Org.get_by_id(ap.campaign.org_id)
    do 
      cnf = Proca.Confirm.LaunchPage.create(ap)
      Proca.Server.Notify.org_confirm_created(cnf, org)

      {:ok, %{status: :confirming}}
    else 
      nil -> {:error, [%{message: "action page not found"}]}
    end
  end
end
