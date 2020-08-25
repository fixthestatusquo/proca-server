defmodule ActionPageTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]

  alias Proca.{Repo, ActionPage}

  setup do
    {:ok, red_story()}
  end

  test "red org can update their red action page by id", %{red_org: red_org, red_campaign: red_camp, red_ap: red_ap} do
    ActionPage.upsert(red_org, red_camp, %{
          id: red_ap.id,
          locale: "en",
          name: "https://stop-fires.org/petition"
                      }) |> Repo.insert_or_update!

    ap = ActionPage.find(red_ap.id)

    assert ap.name == "stop-fires.org/petition"
  end

  test "Action page validates name format" do
    [
      {"https://act.movemove.org/petition1", true},
      {"act.movemove.org/petition/a", true},
      {"act_now.movemove.org/petition/a", false},
      {"act-now.movemove.org/petition/a", true},
      {"org_name", false},
      {"org_name/petition", true},
      {"org_name", false},
      {"org-name/petition", true},
      {"test_this.now/123", false},
      {"https://org-name/petition", true},
      {"https://org-name/campaign-locale-34", true},
      {"https://org-name/campaign/locale/34", true},
      {"https://org-name", false},
      {"ftp://org-name", false},
      {"https://test/", false},
      {"https:///test", false},
      {"domain.pl/../../../../etc/shadow", false},
      {"domain.pl////", false},
    ]
    |> Enum.each(fn {name, is_valid} ->
      ch = ActionPage.changeset(%ActionPage{locale: "en"}, %{name: name})
      assert %{valid?: ^is_valid} = ch
    end)
  end
end
