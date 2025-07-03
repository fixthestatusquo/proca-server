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
end
