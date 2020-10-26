defmodule ProcaWeb.ExportActionResolverTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [blue_story: 0]
  alias Proca.Factory

  doctest ProcaWeb.Resolvers.ExportActions

  @export_via_api_perms Proca.Staffer.Permission.add(0, [:use_api, :export_contacts])

  setup do
    %{org: org, pages: [ap]} = blue_story()

    admin = Factory.insert(:staffer, org: org, perms: @export_via_api_perms)
    actions = Factory.insert_list(3, :action,  %{action_page: ap, action_type: "signature"})

    %{
      org: org,
      admin: admin,
      action_page: ap,
      actions: actions
    }
  end

  test "exportAction for org", %{org: org, action_page: ap, actions: actions, admin: %{user: user}} do
    {:ok, l} = ProcaWeb.Resolvers.ExportActions.export_actions(nil, %{org_name: ap.org.name}, %{context: %{user: user}})

    assert Enum.count(l) == 3
  end
end
