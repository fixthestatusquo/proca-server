defmodule Proca.Confirm.LaunchPage do
   @moduledoc """
   Confirm operation of making action page live.

   Who is the subject? -> Campaign id
   1. Campaign lead
   2. Campaign manager (we have a persmission for this) (we have launch_action_page permission)
   """
   alias Proca.Confirm
   @behaviour Confirm.Operation

   alias Proca.{Campaign, ActionPage, Staffer, Org}
   import Proca.Repo
   import Ecto.Query, only: [from: 2]

   import ProcaWeb.Helper, only: [has_error?: 3, cant_msg: 1, msg_ext: 2]
   import Proca.Staffer.Permission, only: [can?: 2]

   def create(%ActionPage{id: ap_id, campaign_id: campaign_id}) do
      # XXX test for campaign manager
      %{
         operation: :launch_page,
         subject_id: campaign_id,
         object_id: ap_id
      }
      |> Confirm.create()
   end


   defp can_approve?(user_id, campaign) do
      case Staffer.for_user_in_org(%Proca.Users.User{id: user_id}, campaign.org_id) do 
         nil -> false 
         staffer -> can?(staffer, [:manage_campaigns])
      end
   end

   @impl true
   def run(
   %Confirm{
      operation: :launch_page,
      subject_id: campaign_id,
      object_id: ap_id
      },
      :confirm,
      st
      ) do

   with camp when not is_nil(camp) <- get(Campaign, campaign_id),
      ap when not is_nil(ap) <- ActionPage.find(ap_id),
      {:perms, true} <- {:perms, can_approve?(st.user_id, camp)} do

         ActionPage.go_live(ap)
      else
         nil -> {:error, msg_ext("campaign not found", "not_found")}
         {:perms, false} -> {:error, cant_msg([:manage_campaigns])}
      end
   end

   # XXX remove the AP? Rude but makes sense
   @impl true
   def run(%Confirm{operation: :launch_page}, :reject, _st), do: :ok


   @impl true
   def email_template(%Confirm{operation: :launch_page}), do: "launch_page"


   @impl true
   def email_fields(%Confirm{subject_id: campaign_id, object_id: ap_id}) do 
      %Campaign{name: campaign_name, title: campaign_title} = get(Campaign, campaign_id)
      %ActionPage{org: %{name: org_name, title: org_title}} = ActionPage.find(ap_id)
      %{
         "campaign_name" => campaign_name,
         "campaign_title" => campaign_title,
         "org_name" => org_name,
         "org_title" => org_title
      }
   end



end
