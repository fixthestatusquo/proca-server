defmodule Proca.ActionFieldsTest do
  use Proca.DataCase
  doctest Proca.Action
  alias Proca.Action
  alias Proca.Factory
  import Proca.StoryFactory, only: [blue_story: 0]

  setup do
    blue_story()
  end

  test "Action fields are properly validated", %{pages: [action_page]} do
    custom_fields = fn fields ->
      supporter = Factory.insert(:supporter, action_page: action_page)

      ch =
        Action.build_for_supporter(%{action_type: "test", fields: fields}, supporter, action_page)

      ch
    end

    assert custom_fields.(%{}).valid?
    assert not custom_fields.([]).valid?
    assert custom_fields.(%{"foo" => "bar"}).valid?
    assert custom_fields.(%{"foo" => 9999}).valid?
    assert custom_fields.(%{"foo" => [1, 2, 3]}).valid?
    assert custom_fields.(%{"foo" => ["a", "bb", "ccc"]}).valid?
    assert not custom_fields.(%{"foo" => ["a", 2, "ccc"]}).valid?
    assert not custom_fields.(%{"aaa" => nil}).valid?
  end
end
