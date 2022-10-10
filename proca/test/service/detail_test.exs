defmodule Proca.Service.DetailTest do
  use Proca.DataCase
  alias Proca.Factory

  alias Proca.StoryFactory
  alias Proca.Service.Detail
  alias Ecto.Changeset

  describe "update" do
    setup do
      %{pages: [ap]} = StoryFactory.blue_story()
      action = Factory.insert(:action, %{action_page: ap, opt_in: false})

      %{
        supporter: action.supporter,
        action: action,
        action_page: ap
      }
    end

    test "no details", %{action: ac, supporter: sup} do
      {s, a} = Detail.update(Changeset.change(sup), Changeset.change(ac), %Detail{})

      assert map_size(s.changes) == 0
      assert map_size(a.changes) == 0
    end

    test "opt in", %{action: ac, supporter: sup} do
      {s, a} =
        Detail.update(
          Changeset.change(sup),
          Changeset.change(ac),
          %Detail{privacy: %Detail.Privacy{opt_in: true, given_at: "2021-07-28T10:00:00Z"}}
        )

      s2 = Changeset.apply_changes(s)

      assert hd(sup.contacts).communication_consent == false
      assert hd(s2.contacts).communication_consent == true
      assert map_size(a.changes) == 0
    end

    test "double opt in", %{action: ac, supporter: sup} do
      {s, _a} =
        Detail.update(
          Changeset.change(sup),
          Changeset.change(ac),
          %Detail{
            privacy: %Detail.Privacy{
              email_status: "double_opt_in",
              email_status_changed: "2022-06-10T14:20:57.619735Z"
            }
          }
        )

      s2 = Changeset.apply_changes(s)

      assert sup.email_status == :none
      assert s2.email_status == :double_opt_in
      assert s2.email_status_changed.month == 6
      assert s2.email_status_changed.day == 10
    end
  end
end
