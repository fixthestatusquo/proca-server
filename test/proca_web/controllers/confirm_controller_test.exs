defmodule ProcaWeb.ConfirmControllerTest do
  use ProcaWeb.ConnCase, async: false

  import Ecto.Changeset

  alias Proca.{Factory, Repo}
  alias Proca.{Action, Supporter}

  setup do
    ap = Factory.insert(:action_page)
    action = Factory.insert(:action, action_page: ap, with_consent: true)

    Repo.update!(change(action.supporter, processing_status: :confirming))
    action = Repo.preload(Repo.get!(Action, action.id), [:supporter, action_page: :org])

    ref = Supporter.base_encode(action.supporter.fingerprint)

    %{action: action, ref: ref}
  end

  describe "supporter confirm with ?reminder=1" do
    test "emits telemetry event on successful confirm", %{conn: conn, action: action, ref: ref} do
      telemetry_events = :ets.new(:telemetry_test, [:bag, :public])

      :telemetry.attach(
        "test-reminder-confirm",
        [:proca, :email, :reminder_confirm],
        fn event, measurements, metadata, _ ->
          :ets.insert(telemetry_events, {event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("test-reminder-confirm") end)

      conn =
        get(
          conn,
          "/link/s/#{action.id}/accept/#{ref}?reminder=1"
        )

      assert conn.status == 200
      events = :ets.lookup(telemetry_events, [:proca, :email, :reminder_confirm])
      assert length(events) == 1
      {_, %{count: 1}, %{org_id: org_id}} = hd(events)
      assert org_id == action.action_page.org_id
    end

    test "does not emit telemetry without ?reminder=1", %{conn: conn, action: action, ref: ref} do
      telemetry_events = :ets.new(:telemetry_test_no_remind, [:bag, :public])

      :telemetry.attach(
        "test-no-reminder-confirm",
        [:proca, :email, :reminder_confirm],
        fn event, measurements, metadata, _ ->
          :ets.insert(telemetry_events, {event, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach("test-no-reminder-confirm") end)

      get(conn, "/link/s/#{action.id}/accept/#{ref}")

      events = :ets.lookup(telemetry_events, [:proca, :email, :reminder_confirm])
      assert events == []
    end
  end
end
