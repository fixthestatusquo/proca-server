defmodule Proca.Confirm.LaunchPageTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Factory

  alias Proca.{Confirm, Repo, Org}
  import Ecto.Changeset

  use Proca.TestEmailBackend
  @moduletag start: [:notify]

  setup do
    red_story()
  end

  test "email variables contain twitter meta", %{
    yellow_org: yellow_org,
    yellow_user: yellow_user,
    yellow_owner: yellow_owner,
    red_user: red_user,
    red_ap: red_ap
  } do
    change(yellow_org,
      config: %{
        "twitter" => %{
          "id" => 12345,
          "url" => "https://example.com",
          "lang" => nil,
          "name" => "Example Twitter Profile",
          "picture" =>
            "https://pbs.twimg.com/profile_images/1354479643882004483/Btnfm47p_400x400.jpg",
          "location" => "USA",
          "created_at" => "2016-02-11",
          "description" => "A sample campaigning organisation in social media",
          "screen_name" => "ExampleOrg",
          "friends_count" => 100,
          "statuses_count" => 400_000,
          "followers_count" => 100_000
        }
      }
    )
    |> Repo.update!()

    {:ok, new_page} =
      Repo.insert(
        Proca.ActionPage.create_copy_in(yellow_org, red_ap, %{name: red_ap.name <> "/partner"})
      )

    assert yellow_owner.id != nil
    auth = %Proca.Auth{user: yellow_user, staffer: yellow_owner}

    cnf =
      Confirm.LaunchPage.changeset(new_page, auth, "Request message")
      |> Confirm.insert_and_notify!()

    assert cnf.message == "Request message"
    assert cnf.creator_id != nil

    owner_mbox = Proca.TestEmailBackend.mailbox(red_user.email)

    [%{assigns: all_perso_fields}] = owner_mbox

    pf = all_perso_fields

    assert pf["creatorEmail"] == yellow_owner.user.email
    assert pf["orgTwitterDescription"] == "A sample campaigning organisation in social media"

    assert pf["orgTwitterPicture"] ==
             "https://pbs.twimg.com/profile_images/1354479643882004483/Btnfm47p_400x400.jpg"

    assert pf["orgTwitterFollowersCount"] == 100_000
  end
end
