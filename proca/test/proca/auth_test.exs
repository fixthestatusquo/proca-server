defmodule Proca.AuthTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Auth

  setup do
    red_story()
  end

  test "resolve staffer for red user", %{
    red_org: org,
    red_ap: ap,
    red_user: user,
    yellow_org: org2,
    red_campaign: camp
  } do
    user_id = user.id

    assert %Auth{
             staffer: %Proca.Staffer{user_id: ^user_id},
             user: ^user
           } = Auth.get_for_user(org, user)

    assert %Auth{
             staffer: %Proca.Staffer{user_id: ^user_id},
             user: ^user
           } = Auth.get_for_user(camp, user)
  end

  test "resolve staffer for yellow user by campaign", %{
    yellow_campaign: camp,
    yellow_user: user,
    yellow_ap: ap
  } do
    user_id = user.id

    assert %Auth{
             staffer: %Proca.Staffer{user_id: ^user_id},
             user: ^user
           } = Auth.get_for_user(camp, user)

    assert %Auth{
             staffer: %Proca.Staffer{user_id: ^user_id},
             user: ^user
           } = Auth.get_for_user(ap, user)
  end
end
