defmodule Proca.Stages.ProcessOldTest do 
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  alias Proca.Factory 
  alias Proca.Stages.ProcessOld
  alias Proca.Repo

  setup do 
    blue_story()
  end

  test "process old action with new/new status", %{pages: [ap]} do 
    action = Factory.insert(:action, 
      action_type: "signature", 
      action_page: ap, 
      inserted_at: ~N[2020-01-01 10:00:00])

    assert action.processing_status == :new
    assert action.supporter.processing_status == :new


    ProcessOld.process_batch()

    action = action
    |> Repo.reload
    |> Repo.preload([:supporter])

    if Proca.Pipes.enabled? do
      assert action.processing_status == :delivered
      assert action.supporter.processing_status == :accepted
    else
      assert action.processing_status == :new
      assert action.supporter.processing_status == :new

    end

  end

end
