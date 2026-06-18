defmodule OrgTest do
  use Proca.DataCase

  alias Proca.{Repo, Org}
  alias Proca.Service.EmailBudget
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

  # org_factory's default email_backend isn't actually persisted/attached (its id
  # is assigned before insert), so build orgs with a real, attached fallback
  # backend the same way Proca.TestEmailBackend does.
  defp org_with_email_backend() do
    org = Factory.insert(:org)
    backend = Factory.insert(:email_backend, org: org, name: :testmail)

    org
    |> change(email_backend_id: backend.id)
    |> Repo.update!()
    |> Repo.preload(:email_backend)
  end

  defp attached_service(org, name) do
    Factory.insert(:email_backend, org: org, name: name)
  end

  describe "for_transactional_email/2" do
    test "leaves org untouched when no transactional_email_backend is configured" do
      org = org_with_email_backend()

      assert Org.for_transactional_email(org) == org
    end

    test "swaps in transactional_email_backend when no budget is set" do
      org = org_with_email_backend()
      transactional = attached_service(org, :brevo)

      org = %{org | transactional_email_backend: transactional, transactional_email_budget: nil}

      result = Org.for_transactional_email(org, 1000)

      assert result.email_backend.id == transactional.id
    end

    test "falls back to email_backend once the budget is exhausted" do
      org = org_with_email_backend()
      fallback = org.email_backend
      transactional = attached_service(org, :ses)

      org = %{org | transactional_email_backend: transactional, transactional_email_budget: 5}

      # first 5 emails go via the transactional (warming) backend
      assert %{email_backend: %{id: id}} = Org.for_transactional_email(org, 3)
      assert id == transactional.id

      assert %{email_backend: %{id: id}} = Org.for_transactional_email(org, 2)
      assert id == transactional.id

      # budget is now exhausted, further sends fall back
      assert %{email_backend: %{id: id}} = Org.for_transactional_email(org, 1)
      assert id == fallback.id

      assert %{email_backend: %{id: id}} = Org.for_transactional_email(org, 1)
      assert id == fallback.id
    end

    test "budget is tracked in memory per org id, independent of other orgs" do
      org1 = org_with_email_backend()
      transactional1 = attached_service(org1, :ses)
      org1 = %{org1 | transactional_email_backend: transactional1, transactional_email_budget: 1}

      org2 = org_with_email_backend()
      transactional2 = attached_service(org2, :ses)
      org2 = %{org2 | transactional_email_backend: transactional2, transactional_email_budget: 1}

      assert %{email_backend: %{id: id}} = Org.for_transactional_email(org1, 1)
      assert id == transactional1.id

      # org2's budget hasn't been touched by org1's sends
      assert %{email_backend: %{id: id}} = Org.for_transactional_email(org2, 1)
      assert id == transactional2.id

      assert EmailBudget.count(org1.id) == 1
      assert EmailBudget.count(org2.id) == 1
    end
  end

  describe "changeset transactional_email_backend: :system" do
    test "resolves to the instance org's own email backend" do
      instance_org =
        case Org.one([:instance]) do
          nil -> Repo.insert!(%Org{name: Org.instance_org_name(), title: "Instance Org"})
          o -> o
        end

      instance_backend = attached_service(instance_org, :ses)

      instance_org
      |> change(email_backend_id: instance_backend.id)
      |> Repo.update!()

      org = Factory.insert(:org)

      ch = Org.changeset(org, %{transactional_email_backend: :system})
      assert ch.valid?
      assert get_change(ch, :transactional_email_backend_id) == instance_backend.id
    end
  end
end
