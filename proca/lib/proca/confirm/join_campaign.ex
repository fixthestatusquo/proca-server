defmodule Proca.Confirm.JoinCampaign do 
  alias Proca.Confirm
  alias Proca.{Campaign, ActionPage, Staffer, Org}
  alias Proca.Repo
  import Ecto.Query

  import ProcaWeb.Helper, only: [has_error?: 3, cant_msg: 1, msg_ext: 2]
  import Proca.Staffer.Permission, only: [can?: 2]

  def create(%Campaign{id: campaign_id} = campaign, %Staffer{org_id: org_id} = st) do 
    # XXX test for campaign manager
    %{
      operation: :join_campaign,
      subject_id: org_id,
      object_id: campaign_id
    } |> Confirm.create()
  end

  defp can_approve?(saffer, campaign) do 
    staffer.org_id == campaign.org_id and can?(staffer, [:manage_campaigns])
  end

  def run(%Confirm{
    operation: :join_campaign,
    subject_id: org_id,
    object_id: campaign_id
  }, :confirm, st) do

    with 
      org <- Org.get_by_id(org-id) when not is_nil(org),
      c <- Campaign.get_with_local_pages(campaign_id) when not is_nil(c),
      {:p, true} <- {:p, can_approve?(st, c)},
      [page | _] <- c.action_pages
     do
      new_name = org.name <> "/" <> ActionPage.name_path(page.name)

      Confirm.AddPartner.try_create_copy(org, page, new_name)
    else
      nil -> {:error, msg_ext("campaign not found", "not_found")}
      {:p, false} -> {:error, cant_msg([:manage_campaigns])}
      [] -> {:error, msg_ext("campaign has no action_pages", "not_found")}
    end
  end

  def run(%Confirm{operation: join_campaign}, :reject, _st), do: :ok     




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

end
