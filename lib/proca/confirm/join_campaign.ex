defmodule Proca.Confirm.JoinCampaign do
  @moduledoc """
  Confirm a request to join campaign.
  Partner sends such request to campaign lead.
  v1. A successful confirm makes live all pages in that campaign for org.
  v2. A successful confirm creates a partnership.
  """
  alias Proca.Confirm
  @behaviour Confirm.Operation
  alias Proca.{Campaign, ActionPage, Staffer, Org, Auth}
  alias Proca.Repo
  import Ecto.Query

  import ProcaWeb.Helper, only: [cant_msg: 1, msg_ext: 2]
  import Proca.Permission, only: [can?: 2]

  def changeset(%Campaign{id: campaign_id}, %Auth{staffer: %Staffer{org_id: org_id}}) do
    # XXX test for campaign manager
    %{
      operation: :join_campaign,
      subject_id: org_id,
      object_id: campaign_id
    }
  end

  defp can_approve?(staffer, campaign) do
    staffer.org_id == campaign.org_id and can?(staffer, [:manage_campaigns])
  end

  def run(
        %Confirm{
          operation: :join_campaign,
          subject_id: org_id,
          object_id: campaign_id
        },
        :confirm,
        %Auth{staffer: st}
      ) do
    with org when not is_nil(org) <- Org.get_by_id(org_id),
         c when not is_nil(c) <- Repo.get(Campaign, campaign_id),
         {:perms, true} <- {:perms, can_approve?(st, c)} do
      from(ap in ActionPage,
        where: ap.org_id == ^org_id and ap.campaign_id == ^campaign_id and ap.live == false
      )
      |> Repo.update_all(live: true)

      :ok
    else
      nil -> {:error, msg_ext("campaign not found", "not_found")}
      {:perms, false} -> {:error, cant_msg([:manage_campaigns])}
    end
  end

  def run(%Confirm{operation: :join_campaign}, :reject, _auth), do: :ok

  def notify_fields(%Confirm{}), do: %{}

  def email_template(%Confirm{operation: :join_campaign}), do: "join_campaign"

  #    latest_page = from(a in ActinPage,
  #      where: a.campaign_id == ^campaign_id and a.org_id ==,
  #      order_by: [desc: :id]
  #      ) |> Repo.one
  #
  #    with {:page, page = %ActionPage{}} <- {:page, latest_page},
  #        true <- st.org_id ==
  #        true <- can?(st, [:manage_action_pages])
  #      do
end
