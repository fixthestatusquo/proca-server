defmodule OrgTest do
  use Proca.DataCase

  alias Proca.{Repo, Org}
  import Ecto.Changeset

  test "Can't create two orgs with same name but different case" do
    assert {:ok, _o1} = Org.changeset(%Org{}, %{name: "IETF", title: "test1"}) |> Repo.insert()

    assert {:error,
            %{
              errors: [
                {
                  :name,
                  {_, [{:constraint, :unique} | _]}
                }
              ]
            }} = Org.changeset(%Org{}, %{name: "ietf", title: "test2"}) |> Repo.insert()
  end
end
