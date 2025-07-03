defmodule Proca.Stage.ProcessOldTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  alias Proca.Factory
  alias Proca.Pipes

  setup do
    blue_story()
  end

  test "Test the producer of old actions", %{pages: [ap]} do
    action =
      Factory.insert(:action,
        action_type: "signature",
        action_page: ap,
        inserted_at: ~N[2020-01-01 10:00:00]
      )

    assert action.processing_status == :new
    assert action.supporter.processing_status == :new

    assert Pipes.Connection.is_connected?()

    [action2] = Proca.Stage.UnprocessedActions.unprocessed_actions(1, 0, 0)

    assert action.id == action2.id
  end
end
