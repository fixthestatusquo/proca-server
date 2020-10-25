defmodule AuthenticatedTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]

  alias ProcaWeb.Schema.Authenticated

  setup do
    s = red_story()

    r1 = %Absinthe.Resolution{}
    r2 = %{r1 | context: %{user: s.red_bot.user}}
    r3_id = %{r2 | arguments: %{id: s.red_org.id}}
    r3_name = %{r2 | arguments: %{name: s.red_org.name}}
    r3_org_name = %{r2 | arguments: %{org_name: s.red_org.name}}

    s
    |> Map.merge(%{
          resolution: r1,
          user_resolution: r2,
          org_id_resolution: r3_id,
          org_name_resolution: r3_name,
          org_org_name_resolution: r3_org_name
                 })
    
  end

  test "Fail when no user in context", %{resolution: r} do
    r = Authenticated.call(r, [])
    assert r.errors == ["unauthenticated"]
  end

  test "Return resolution where user in context", %{user_resolution: r} do
    r2 = Authenticated.call(r, [])
    assert r == r2
  end

  test "Staffer search by org but no arguments", %{user_resolution: r} do
    r2 = Authenticated.call(r, [can?: {:org, []}]) 
    assert r2.errors == ["not_found"]
  end

  test "Staffer search by org with id argument", %{org_id_resolution: r, red_bot: staffer, red_org: org} do
    r2 = Authenticated.call(r, [can?: {:org, []}]) 
    assert r2.errors == []
    assert r2.context.staffer.id == staffer.id
    assert r2.context.org.id == org.id
  end

  test "Staffer search by org with name argument", %{org_name_resolution: r, red_bot: staffer, red_org: org} do
    r2 = Authenticated.call(r, [can?: {:org, []}]) 
    assert r2.errors == []
    assert r2.context.staffer.id == staffer.id
    assert r2.context.org.id == org.id

    r3 = Authenticated.call(r, [can?: {:org, [:manage_campaigns]}]) 
    assert r3.errors == []
    assert r3.context.staffer.id == staffer.id
    assert r3.context.org.id == org.id

    r4 = Authenticated.call(r, [can?: {:org, [:signoff_action_page]}]) 
    assert r4.errors == ["permission_denied"]
  end


  test "Staffer search by org with org_name argument", %{org_org_name_resolution: r, red_org: org} do
    r2 = Authenticated.call(r, [can?: {:org, [:manage_campaigns]}, get_by: [name: :org_name]]) 
    assert r2.context.org.id == org.id
  end

  test "Staffer search by campaign", %{user_resolution: r, red_campaign: camp} do
    r2 = %{r | arguments: %{name: camp.name}}
    r3 = Authenticated.call(r2, [can?: {:campaign, []}])
    assert r3.context.campaign.id == camp.id
  end

  test "Staffer search by action page", %{user_resolution: r, red_ap: ap} do
    r2 = %{r | arguments: %{name: ap.name}}
    r3 = Authenticated.call(r2, [can?: {:action_page, []}])
    assert r3.context.action_page.id == ap.id
  end
end
