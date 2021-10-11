defmodule Proca.Confirm.LaunchPageTest do 
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Factory

  alias Proca.{Confirm, Repo, Org}
  alias Proca.TestEmailBackend
  import Ecto.Changeset

  setup do 
    io = Org.instance_org_name()
    |> Org.get_by_name([:template_backend, :email_backend])

    io = io
    |> Org.put_service(Factory.insert(:email_backend, org: io))
    |> Repo.update!

    red_story()
    |> Map.put(:instance, io)
    |> Map.put(:email_backend, TestEmailBackend.start_link([]))
    |> Map.put(:template_directory, Proca.Service.EmailTemplateDirectory.start_link([]))
  end

  test "email variables contain twitter meta", %{
    yellow_org: yellow_org, yellow_user: yellow_user, yellow_owner: yellow_owner, red_ap: red_ap
  } do 
    change(yellow_org, config: %{
      "twitter" => %{
        "id"=> 12345, 
        "url"=> "https://example.com", 
        "lang"=> nil, 
        "name"=> "Example Twitter Profile", 
        "picture"=> "https://pbs.twimg.com/profile_images/1354479643882004483/Btnfm47p_400x400.jpg", 
        "location"=> "USA", 
        "created_at"=> "2016-02-11", 
        "description"=> "A sample campaigning organisation in social media", 
        "screen_name"=> "ExampleOrg", 
        "friends_count"=> 100, 
        "statuses_count"=> 400000, 
        "followers_count"=> 100000
      }
    }) |> Repo.update!
    
    {:ok, new_page} = Proca.ActionPage.create_copy_in(yellow_org, red_ap, %{name: red_ap.name <> "/partner"})
    assert yellow_owner.id != nil
    auth = %Proca.Auth{user: yellow_user, staffer: yellow_owner}
    cnf = Confirm.LaunchPage.create(new_page, auth, "Request message")

    assert cnf.message == "Request message"
    assert cnf.creator_id != nil

    Proca.Server.Notify.org_confirm_created(cnf, yellow_org)

    owner_mbox = Proca.TestEmailBackend.mailbox yellow_owner.user.email    

    [%{private: %{fields: all_perso_fields}}] = owner_mbox

    pf = all_perso_fields[yellow_owner.user.email]

    assert pf["confirm_creator_email"] == yellow_owner.user.email
    assert pf["org_twitter_description"] == "A sample campaigning organisation in social media"
    assert pf["org_twitter_picture"] == "https://pbs.twimg.com/profile_images/1354479643882004483/Btnfm47p_400x400.jpg"
    assert pf["org_twitter_followers_count"] == 100000


  end
end
