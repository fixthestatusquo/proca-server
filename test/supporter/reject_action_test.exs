defmodule Proca.Supporter.RejectActionTest do
  use Proca.DataCase

  alias Proca.{Action, Factory, Repo, Supporter}
  alias Proca.Supporter.RejectAction

  test "reject action force-rejects action/supporter, revokes DOI, and emits notify" do
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
             RejectAction.run(action,
               notify_fun: fn supporter, opts ->
                 send(self(), {:notify, supporter.id, opts})
                 :ok
               end
             )

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

  test "reject action force-rejects without notify when email status does not change" do
    action = Factory.insert(:action, processing_status: :new, supporter_processing_status: :new)

    assert {:ok, %{email_status_changed?: false}} =
             RejectAction.run(action,
               notify_fun: fn _supporter, _opts ->
                 send(self(), :notify)
                 :ok
               end
             )

    updated_supporter = Repo.get!(Supporter, action.supporter_id)
    updated_action = Repo.get!(Action, action.id)

    assert updated_supporter.processing_status == :rejected
    assert updated_action.processing_status == :rejected
    assert updated_supporter.email_status == :none
    refute_received :notify
  end

  test "reject action is idempotent and only notifies once for DOI revoke" do
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
             RejectAction.run(action,
               notify_fun: fn _supporter, _opts ->
                 send(self(), :notify_once)
                 :ok
               end
             )

    assert {:ok, %{email_status_changed?: false}} =
             RejectAction.run(action2,
               notify_fun: fn _supporter, _opts ->
                 send(self(), :notify_twice)
                 :ok
               end
             )

    assert_received :notify_once
    refute_received :notify_twice
  end

  test "reject action can set explicit email status and skip notify" do
    action =
      Factory.insert(:action,
        processing_status: :accepted,
        supporter_processing_status: :accepted
      )

    assert {:ok, %{email_status_changed?: true}} =
             RejectAction.run(action,
               email_status: :bounce,
               notify: false,
               notify_fun: fn _supporter, _opts ->
                 send(self(), :notify)
                 :ok
               end
             )

    updated_supporter = Repo.get!(Supporter, action.supporter_id)
    updated_action = Repo.get!(Action, action.id)

    assert updated_supporter.processing_status == :rejected
    assert updated_action.processing_status == :rejected
    assert updated_supporter.email_status == :bounce
    refute_received :notify
  end
end
