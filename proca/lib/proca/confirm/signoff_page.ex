defmodule Proca.Confirm.SignoffPage do
  @moduledoc """
  Confirm operation of making action page live.

  Who is the subject? -> Campaign id
  1. Campaign lead
  2. Campaign manager (we have a persmission for this) (we have signoff_action_page permission)
  """
  alias Proca.Confirm
  alias Proca.{Campaign, ActionPage, Staffer, Org}
  alias Proca.Repo
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

  def run(
        %Confirm{
          operation: :signoff_page,
          subject_id: campaign_id,
          object_id: ap_id
        },
        :confirm,
        st
      ) do
    with camp when not is_nil(camp) <- Repo.get(Campaign, campaign_id),
         ap when not is_nil(ap) <- ActionPage.find(ap_id),
         {:perms, true} <- {:perms, can_approve?(st, camp)} do

      ActionPage.go_live(ap)
    else
      nil -> {:error, msg_ext("campaign not found", "not_found")}
      {:perms, false} -> {:error, cant_msg([:manage_campaigns])}
    end
  end

  def run(%Confirm{operation: :signoff_page}, :reject, _st), do: :ok
  # XXX remove the AP? Rude but makes sense
end

