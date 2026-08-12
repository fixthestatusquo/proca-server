defmodule Mix.Tasks.Proca.BackfillOwnerDeleteContactsTest do
  use Proca.DataCase

  import ExUnit.CaptureIO
  import Proca.Permission, only: [add: 2, can?: 2]

  alias Proca.{Factory, Repo}

  setup do
    Mix.Task.clear()
    :ok
  end

  test "dry run reports impacted legacy owners without mutating perms" do
    org = Factory.insert(:org, name: "legacy-org")
    legacy_owner = Factory.insert(:staffer, org: org, perms: legacy_owner_perms())
    Factory.insert(:staffer, org: org, perms: add(0, Proca.Staffer.Role.permissions(:owner)))
    legacy_owner_email = legacy_owner.user.email

    output =
      capture_io(fn ->
        Mix.Task.run("proca.backfill_owner_delete_contacts")
      end)

    legacy_owner = Repo.reload!(legacy_owner)

    assert output =~ "legacy owners missing delete_contacts: 1"
    assert output =~ legacy_owner_email
    refute can?(legacy_owner, :delete_contacts)
  end

  test "apply mode only updates scoped org and is idempotent" do
    target_org = Factory.insert(:org, name: "target-org")
    other_org = Factory.insert(:org, name: "other-org")

    scoped_owner = Factory.insert(:staffer, org: target_org, perms: legacy_owner_perms())
    untouched_owner = Factory.insert(:staffer, org: other_org, perms: legacy_owner_perms())

    output =
      capture_io(fn ->
        Mix.Task.run("proca.backfill_owner_delete_contacts", ["--apply", "--org", target_org.name])
      end)

    scoped_owner = Repo.reload!(scoped_owner)
    untouched_owner = Repo.reload!(untouched_owner)

    assert output =~ "updated staffers: 1"
    assert can?(scoped_owner, :delete_contacts)
    refute can?(untouched_owner, :delete_contacts)

    second_output =
      capture_io(fn ->
        Mix.Task.reenable("proca.backfill_owner_delete_contacts")
        Mix.Task.run("proca.backfill_owner_delete_contacts", ["--apply", "--org", target_org.name])
      end)

    assert second_output =~ "updated staffers: 0"
  end

  defp legacy_owner_perms do
    Proca.Permission.add(0, Proca.Staffer.Role.permissions(:owner))
    |> Proca.Permission.remove(:delete_contacts)
  end
end
