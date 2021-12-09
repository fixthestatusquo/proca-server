defmodule ProcaWeb.Resolvers.ActionPage do
  @moduledoc """
  Resolvers for action page related mutations
  """
  import Ecto.Query
  alias Proca.{ActionPage, Campaign, Org}
  alias Proca.Repo
  alias Proca.Auth
  alias ProcaWeb.Helper

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
  def copy_from(_, %{name: name}, %{context:
                                    %{
                                      action_page: ap,
                                      org: org
                                    }}) do
    ActionPage.create_copy_in(org, ap, %{name: name})
    |> Repo.insert_and_notify()
  end

  @doc """
  Copy any action page in campaign. The new copy is owned by caller org.
  """
  def copy_from_campaign(_, %{name: name}, %{context:
                                             %{
                                               org: org,
                                               campaign: campaign
                                             }}) do
    case campaign.action_pages do
      [ap | _ ] ->
        ActionPage.create_copy_in(org, ap, %{name: name})
        |> Repo.insert_and_notify()
      [] -> {:error, "Campaign #{campaign.name} does not have action pages"}
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

  def launch_page(_, params,
    %{context: %{
         auth: auth = %Auth{staffer: %{id: org_id}},
         action_page: ap
      }}) do

    case Org.get_by_id(ap.campaign.org_id) do
      %Org{id: ^org_id} ->
        case ActionPage.go_live(ap) do
          {:ok, _} -> {:ok, %{status: :success}}
          {:error, _ch} = e -> e
        end
      _ ->
        Proca.Confirm.LaunchPage.changeset(ap, auth, Map.get(params, :message))
        |> Proca.Confirm.insert_and_notify!()

        {:ok, %{status: :confirming}}
    end
  end
end
