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
    r =
      ProcaWeb.Resolvers.Org.add_org(0, %{input: p}, %{context: %{auth: %Proca.Auth{user: user}}})

    assert {:middleware, ProcaWeb.Resolvers.ChangeAuth, {auth, {:ok, o}}} = r
    %{name: name} = o
    assert name == p[:name]
    assert not is_nil(auth.staffer)
    assert auth.staffer.org.name == p[:name]
  end

  test "Can't add an org with incorrect params", %{user: user, org_params: p} do
    bad_name = %{p | name: "test!"}

    er =
      ProcaWeb.Resolvers.Org.add_org(0, %{input: bad_name}, %{
        context: %{auth: %Proca.Auth{user: user}}
      })

    assert {:error,
            %Ecto.Changeset{errors: [{:name, {"has invalid format", [validation: :format]}} | _]}} =
             er

    no_title = Map.delete(p, :title)

    er =
      ProcaWeb.Resolvers.Org.add_org(0, %{input: no_title}, %{
        context: %{auth: %Proca.Auth{user: user}}
      })

    assert {:error, %Ecto.Changeset{errors: [{:title, {"can't be blank", _}} | _]}} = er
  end

  describe "update_org_processing - transactional email backend" do
    setup do
      org = Factory.insert(:org)
      transactional_service = Factory.insert(:email_backend, org: org, name: :brevo)

      %{org: org, transactional_service: transactional_service}
    end

    test "sets transactional_email_backend and transactional_email_budget", %{org: org} do
      assert {:ok, updated} =
               ProcaWeb.Resolvers.Org.update_org_processing(
                 0,
                 %{
                   name: org.name,
                   transactional_email_backend: :brevo,
                   transactional_email_budget: 200
                 },
                 %{context: %{org: org}}
               )

      updated = Proca.Repo.preload(updated, [:transactional_email_backend])

      assert updated.transactional_email_backend.name == :brevo
      assert updated.transactional_email_budget == 200
    end

    test "rejects a backend the org doesn't actually have", %{org: org} do
      assert {:error, changeset} =
               ProcaWeb.Resolvers.Org.update_org_processing(
                 0,
                 %{name: org.name, transactional_email_backend: :mailjet},
                 %{context: %{org: org}}
               )

      assert Enum.any?(changeset.errors, fn
               {:transactional_email_backend, {"no such service", _}} -> true
               _ -> false
             end)
    end
  end
end
