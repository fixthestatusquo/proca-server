defmodule Proca.Server.MTTAdvisoryLockTest do
  @moduledoc """
  Regression test for duplicate MTT sends caused by overlapping workers.
  Uses a separate raw Postgrex connection (not the sandboxed test connection)
  since advisory locks are reentrant within one session.
  """

  use Proca.DataCase, async: false

  alias Proca.Factory
  alias Proca.Server.MTT

  setup do
    {:ok, conn} =
      Postgrex.start_link(
        hostname: System.get_env("DATABASE_HOST", "localhost"),
        username: "proca",
        password: "proca",
        database: "proca_test"
      )

    on_exit(fn ->
      if Process.alive?(conn), do: GenServer.stop(conn)
    end)

    campaign = Factory.insert(:campaign, mtt: Factory.build(:mtt_new))

    %{conn: conn, campaign: campaign}
  end

  test "skips processing when another session already holds the campaign's advisory lock",
       %{conn: conn, campaign: campaign} do
    assert %{rows: [[true]]} =
             Postgrex.query!(conn, "SELECT pg_try_advisory_lock($1)", [campaign.id])

    log =
      ExUnit.CaptureLog.capture_log(fn ->
        result = MTT.process_campaign_exclusively(campaign)
        send(self(), {:result, result})
      end)

    assert log =~ "Skipping MTT worker for #{campaign.name}"

    Postgrex.query!(conn, "SELECT pg_advisory_unlock($1)", [campaign.id])
  end

  test "processes normally and releases the lock when no one else holds it", %{
    conn: conn,
    campaign: campaign
  } do
    MTT.process_campaign_exclusively(campaign)

    # If the lock wasn't released, this second, independent session would be
    # unable to acquire it.
    assert %{rows: [[true]]} =
             Postgrex.query!(conn, "SELECT pg_try_advisory_lock($1)", [campaign.id])

    Postgrex.query!(conn, "SELECT pg_advisory_unlock($1)", [campaign.id])
  end
end
