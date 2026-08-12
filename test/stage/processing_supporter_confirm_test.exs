defmodule Proca.Stage.ProcessingSupporterConfirmTest do
  @moduledoc """
  Focused unit tests for the campaign.supporter_confirm tri-state override of
  org supporter_confirm/custom_supporter_confirm, exercised directly against
  Proca.Stage.Processing.transition/2 (no DB, no Broadway pipeline).
  """

  use ExUnit.Case, async: true

  alias Proca.ActionPage
  alias Proca.Stage.Processing

  defp action_page(org_supporter_confirm, campaign_supporter_confirm) do
    %ActionPage{
      org: %{
        supporter_confirm: org_supporter_confirm,
        custom_supporter_confirm: false,
        custom_action_confirm: false
      },
      campaign: %{
        supporter_confirm: campaign_supporter_confirm,
        action_confirm: nil
      }
    }
  end

  describe "effective_supporter_confirm/2" do
    test "nil campaign override defers to the org setting" do
      assert Processing.effective_supporter_confirm(true, nil) == true
      assert Processing.effective_supporter_confirm(false, nil) == false
    end

    test "campaign override wins regardless of org setting" do
      assert Processing.effective_supporter_confirm(false, true) == true
      assert Processing.effective_supporter_confirm(true, false) == false
    end
  end

  describe "transition/2 - fresh action+supporter (first touch)" do
    test "org confirm off, campaign nil -> delivered" do
      action = %{processing_status: :new, supporter: %{processing_status: :new}}
      ap = action_page(false, nil)

      assert Processing.transition(action, ap) == {:delivered, :accepted, :deliver}
    end

    test "org confirm on, campaign nil -> supporter_confirm queue (unchanged default behaviour)" do
      action = %{processing_status: :new, supporter: %{processing_status: :new}}
      ap = action_page(true, nil)

      assert Processing.transition(action, ap) == {:new, :confirming, :supporter_confirm}
    end

    test "org confirm off, campaign forces true -> supporter_confirm queue" do
      action = %{processing_status: :new, supporter: %{processing_status: :new}}
      ap = action_page(false, true)

      assert Processing.transition(action, ap) == {:new, :confirming, :supporter_confirm}
    end

    test "org confirm on, campaign forces false -> delivered (this was the bug: campaign false could not override org true)" do
      action = %{processing_status: :new, supporter: %{processing_status: :new}}
      ap = action_page(true, false)

      assert Processing.transition(action, ap) == {:delivered, :accepted, :deliver}
    end
  end
end
