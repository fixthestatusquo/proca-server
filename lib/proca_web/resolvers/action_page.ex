defmodule ProcaWeb.Resolvers.ActionPage do
  @moduledoc """
  Resolvers for action page related mutations
  """
  alias Proca.{ActionPage, Org}
  alias Proca.Repo
  alias Proca.Auth

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
  def copy_from(_, %{name: name}, %{
        context: %{
          action_page: ap,
          org: org
        }
      }) do
    ActionPage.create_copy_in(org, ap, %{name: name})
    |> Repo.insert_and_notify()
  end

  @doc """
  Copy any action page in campaign. The new copy is owned by caller org.
  """
  def copy_from_campaign(_, %{name: name}, %{
        context: %{
          org: org,
          campaign: campaign
        }
      }) do
    case campaign.action_pages do
      [ap | _] ->
        ActionPage.create_copy_in(org, ap, %{name: name})
        |> Repo.insert_and_notify()

      [] ->
        {:error, "Campaign #{campaign.name} does not have action pages"}
    end
  end

  def add_action_page(_, %{input: input}, %{context: %{org: org, campaign: campaign}}) do
    ActionPage.changeset(%{campaign: campaign, org: org} |> Map.merge(input))
    |> Repo.insert_and_notify()
  end

  # XXX make this into simple update on action_page, after we have partnerships
  def launch_page(_, params, %{
        context: %{
          auth: auth = %Auth{staffer: staffer},
          action_page: ap
        }
      }) do
    # Compare to campaign owner

    staffer =
      staffer || Proca.Staffer.one(org: %Proca.Org{id: ap.campaign.org_id}, user: auth.user)

    org_id = if staffer, do: staffer.org_id, else: nil

    case Org.one(id: ap.campaign.org_id) do
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

  def delete(_, _, %{context: %{action_page: ap}}) do
    res = Repo.transaction_and_notify(ActionPage.delete(ap), :delete_action_page)

    case res do
      {:ok, _ap} -> {:ok, :success}
      e -> e
    end
  end
end
