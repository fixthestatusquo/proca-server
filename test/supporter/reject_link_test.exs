defmodule Proca.Supporter.RejectLinkTest do
  use Proca.DataCase

  alias Proca.{Action, Factory, Repo, Supporter}
  alias Proca.Supporter.RejectLink

  test "reject link force-rejects action/supporter, revokes DOI, and emits notify" do
    action_page = Factory.insert(:action_page)

    supporter =
      Factory.insert(:basic_data_pl_supporter_with_contact,
        action_page: action_page,
        processing_status: :accepted,
        email_status: :double_opt_in
      )

    action =
      Factory.insert(:action,
        supporter: supporter,
        action_page: supporter.action_page,
        processing_status: :delivered
      )

    assert {:ok, %{email_status_changed?: true}} =
             RejectLink.run(action, fn supporter, opts ->
               send(self(), {:notify, supporter.id, opts})
               :ok
             end)

    updated_supporter = Repo.get!(Supporter, supporter.id)
    updated_action = Repo.get!(Action, action.id)

    assert updated_supporter.processing_status == :rejected
    assert updated_action.processing_status == :rejected
    assert updated_supporter.email_status == :unsub
    assert updated_supporter.email_status_changed != nil
    supporter_id = updated_supporter.id
    action_id = updated_action.id
    assert_received {:notify, ^supporter_id, [id: ^action_id]}
  end

  test "reject link force-rejects without notify when email status does not change" do
    action = Factory.insert(:action, processing_status: :new, supporter_processing_status: :new)

    assert {:ok, %{email_status_changed?: false}} =
             RejectLink.run(action, fn _supporter, _opts ->
               send(self(), :notify)
               :ok
             end)

    updated_supporter = Repo.get!(Supporter, action.supporter_id)
    updated_action = Repo.get!(Action, action.id)

    assert updated_supporter.processing_status == :rejected
    assert updated_action.processing_status == :rejected
    assert updated_supporter.email_status == :none
    refute_received :notify
  end

  test "reject link is idempotent and only notifies once for DOI revoke" do
    action_page = Factory.insert(:action_page)

    supporter =
      Factory.insert(:basic_data_pl_supporter_with_contact,
        action_page: action_page,
        processing_status: :accepted,
        email_status: :double_opt_in
      )

    action =
      Factory.insert(:action,
        supporter: supporter,
        action_page: supporter.action_page,
        processing_status: :accepted
      )

    assert {:ok, %{action: action2}} =
             RejectLink.run(action, fn _supporter, _opts ->
               send(self(), :notify_once)
               :ok
             end)

    assert {:ok, %{email_status_changed?: false}} =
             RejectLink.run(action2, fn _supporter, _opts ->
               send(self(), :notify_twice)
               :ok
             end)

    assert_received :notify_once
    refute_received :notify_twice
  end
end
