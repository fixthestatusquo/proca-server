defmodule ProcaWeb.Resolvers.ActionPage do
  @moduledoc """
  Resolvers for action page related mutations
  """
  import Ecto.Query
  alias Proca.{ActionPage, Campaign, Org}
  alias Proca.Repo
  alias ProcaWeb.Helper


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

  # XXX legacy
  def find(_, %{url: url}, _) do
    find_one(&by_name(&1, ActionPage.remove_schema_from_name(url)))
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
    ap
    |> ActionPage.changeset(attrs)
    |> Repo.update_and_notify()
  end

  @doc """
  Copy an action page in campaign. The new copy is owned by caller org.
  """
  def copy_from(_, %{name: name, from_name: from_name}, %{context: %{org: org}}) do
    with ap when not is_nil(ap) <- ActionPage.find(from_name) do
      ActionPage.create_copy_in(org, ap, %{name: name})
      |> Repo.insert_and_notify()
    else
      nil -> {:error, "ActionPage named #{from_name} not found"}
      {:error, %Ecto.Changeset{valid?: false} = ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  @doc """
  Copy any action page in campaign. The new copy is owned by caller org.
  """
  def copy_from_campaign(_, %{name: name, from_campaign_name: camp_name}, %{context: %{org: org}}) do
    with campaign when not is_nil(campaign) <- Campaign.get_with_local_pages(camp_name),
        [ap | _] <- campaign.action_pages do
      ActionPage.create_copy_in(org, ap, %{name: name})
      |> Repo.insert_and_notify()
    else
      nil -> {:error, "Campaign named #{camp_name} not found"}
      [] -> {:error, "Campaign #{camp_name} does not have action pages"}
      {:error, %Ecto.Changeset{valid?: false} = ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def add_action_page(_, %{name: name, campaign_name: cn, locale: locale}, %{context: %{org: org}}) do 
    with campaign when campaign != nil <- Campaign.get(name: cn) do
      ActionPage.changeset(%{
            name: name,
            locale: locale,
            campaign: campaign,
            org: org
                           })
      |> Repo.insert_and_notify()
    else
      nil -> {:error, "Campaign named #{cn} not found"}
      {:error, %Ecto.Changeset{valid?: false} = ch} -> {:error, Helper.format_errors(ch)}
    end
  end

  def launch_page(_, %{name: name} = params, %{context: %{auth: auth, staffer: st}}) do 
    with ap = %ActionPage{} <- ActionPage.find(name),
        org <- Org.get_by_id(ap.campaign.org_id)
    do 
      if st.org_id == org.id do 
        # lead org
        case ActionPage.go_live(ap) do
          {:ok, _} -> {:ok, %{status: :success}}
          {:error, _ch} = e -> e
        end
      else
        # partner org
        Proca.Confirm.LaunchPage.changeset(ap, auth, Map.get(params, :message))
        |> Proca.Confirm.insert_and_notify!()

        {:ok, %{status: :confirming}}
      end
    else 
      nil -> {:error, [%{message: "action page not found"}]}
    end
  end
end
