defmodule ActionPageTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]

  alias Proca.{Repo, ActionPage}

  setup do
    {:ok, red_story()}
  end

  test "red org can update their red action page by id", %{
    red_org: red_org,
    red_campaign: red_camp,
    red_ap: red_ap
  } do
    ActionPage.upsert(red_org, red_camp, %{
      id: red_ap.id,
      locale: "en",
      name: "stop-fires.org/petition"
    })
    |> Repo.insert_or_update!()

    ap = ActionPage.one(id: red_ap.id, preload: [:org, :campaign])

    assert ap.name == "stop-fires.org/petition"
  end

  test "Action page validates name format" do
    [
      {"act.movemove.org/petition1", true},
      {"act.movemove.org/petition/a", true},
      {"act_now.movemove.org/petition/a", false},
      {"act-now.movemove.org/petition/a", true},
      {"org_name", false},
      {"org_name/petition", true},
      {"org_name", false},
      {"org-name/petition", true},
      {"test_this.now/123", false},
      {"org-name/petition", true},
      {"org-name/campaign-locale-34", true},
      {"org-name/campaign/locale/34", true},
      {"org-name", false},
      {"test/", false},
      {"/test", false},
      {"domain.pl/../../../../etc/shadow", false},
      {"domain.pl////", false}
    ]
    |> Enum.each(fn {name, is_valid} ->
      ch = ActionPage.changeset(%ActionPage{locale: "en"}, %{name: name})
      assert %{valid?: ^is_valid} = ch
    end)
  end

  describe "delete/1 is blocked by remaining data" do
    import Ecto.Query
    alias Proca.{Action, Factory}

    defp delete_error(ap) do
      ap_id = ap.id
      assert {:error, {:action_page, ^ap_id}, cs, _} = Repo.transaction(ActionPage.delete(ap))
      Enum.map(cs.errors, fn {field, {msg, _}} -> {field, msg} end)
    end

    test "page with an action", %{red_ap: ap} do
      Factory.insert(:action, action_page: ap)

      assert delete_error(ap) == [actions: "has action data"]
    end

    test "page whose supporter has actions only on another page", %{red_ap: ap} do
      action = Factory.insert(:action, action_page: ap)
      other_ap = Factory.insert(:action_page, org: ap.org, campaign: ap.campaign)

      # the supporter stays on `ap`, its only action moves to `other_ap`
      from(a in Action, where: a.id == ^action.id)
      |> Repo.update_all(set: [action_page_id: other_ap.id])

      assert delete_error(ap) == [supporters: "has suporter data"]
    end
  end
end
