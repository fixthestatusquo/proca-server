defmodule Proca.Confirm.SignoffPage do
   @moduledoc """
   Confirm operation of making action page live.

   Who is the subject? -> Campaign id
   1. Campaign lead
   2. Campaign manager (we have a persmission for this) (we have signoff_action_page permission)
   """
   alias Proca.Confirm
   @behaviour Confirm.Operation

   alias Proca.{Campaign, ActionPage, Staffer, Org}
   import Proca.Repo
   import Ecto.Query

   import ProcaWeb.Helper, only: [has_error?: 3, cant_msg: 1, msg_ext: 2]
   import Proca.Staffer.Permission, only: [can?: 2]

   def create(%ActionPage{id: ap_id, campaign_id: campaign_id}) do
      # XXX test for campaign manager
      %{
         operation: :signoff_page,
         subject_id: campaign_id,
         object_id: ap_id
      }
      |> Confirm.create()
   end


   defp can_approve?(staffer, campaign) do
      staffer.org_id == campaign.org_id and can?(staffer, [:manage_campaigns])
   end

   @impl true
   def run(
   %Confirm{
      operation: :signoff_page,
      subject_id: campaign_id,
      object_id: ap_id
      },
      :confirm,
      st
      ) do
   with camp when not is_nil(camp) <- get(Campaign, campaign_id),
      ap when not is_nil(ap) <- ActionPage.find(ap_id),
      {:perms, true} <- {:perms, can_approve?(st, camp)} do

         ActionPage.go_live(ap)
      else
         nil -> {:error, msg_ext("campaign not found", "not_found")}
         {:perms, false} -> {:error, cant_msg([:manage_campaigns])}
      end
   end

   # XXX remove the AP? Rude but makes sense
   @impl true
   def run(%Confirm{operation: :signoff_page}, :reject, _st), do: :ok


   @impl true
   def email_template(%Confirm{operation: :signoff_page}), do: "signoff_page"


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

