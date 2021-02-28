defmodule ProcaWeb.OrgMutationsTest do
  use Proca.DataCase
  alias Proca.Factory

  setup do
    %{
      user: Factory.insert(:user),
      org_params: %{
        name: "test_org",
        title: "Some Test Now!"
      }
    }
  end

  test "Can add an org", %{user: user, org_params: p} do
    {:ok, o} = ProcaWeb.Resolvers.Org.add_org(0, %{input: p}, %{context: %{user: user}})
    %{name: name} = o
    assert name == p[:name]
  end

  test "Can't add an org with incorrect params", %{user: user, org_params: p} do
    bad_name = %{p | name: "test!"}
    er = ProcaWeb.Resolvers.Org.add_org(0, %{input: bad_name}, %{context: %{user: user}})
    assert {:error, [%{message: "name: has invalid format", path: ["name"]}]} = er

    no_title = Map.delete(p, :title)

    er = ProcaWeb.Resolvers.Org.add_org(0, %{input: no_title}, %{context: %{user: user}})
    assert {:error, [%{message: "title: can't be blank", path: ["title"]}]} = er

  end

end
