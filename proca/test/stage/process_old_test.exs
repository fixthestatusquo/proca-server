defmodule Proca.Stage.ProcessOldTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  alias Proca.Factory
  alias Proca.Stage.ProcessOld
  alias Proca.Repo
  alias Proca.Pipes

  setup do
    blue_story()
    # |> Map.put(:pipes_supervisor, Pipes.Supervisor.start_link([]))
    # |> Map.put(:pipes_connection, Pipes.Connection.start_link(Pipes.queue_url()))
  end

  test "process old action with new/new status", %{pages: [ap]} do
    action =
      Factory.insert(:action,
        action_type: "signature",
        action_page: ap,
        inserted_at: ~N[2020-01-01 10:00:00]
      )

    assert action.processing_status == :new
    assert action.supporter.processing_status == :new

    ProcessOld.process_batch()

    action =
      action
      |> Repo.reload()
      |> Repo.preload([:supporter])

    if Proca.Pipes.enabled?() do
      assert action.processing_status == :delivered
      assert action.supporter.processing_status == :accepted
    else
      assert action.processing_status == :new
      assert action.supporter.processing_status == :new
    end
  end
end
