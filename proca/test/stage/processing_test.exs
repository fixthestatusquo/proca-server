defmodule Proca.Stage.ProcessingTest do
  use Proca.DataCase
  import Proca.StoryFactory
  alias Proca.Stage
  alias Proca.Factory
  import Logger

  setup do
    ctx = teal_story()

    # Set up the topology
    Proca.Server.Notify.start_org_pipes(ctx.org)

    Enum.each(ctx.partners, fn %{org: org} ->
      Proca.Server.Notify.start_org_pipes(org)
    end)

    {:ok, pid} = Stage.Action.start_link([])

    ctx
    |> Map.put(:pid, pid)
  end

  test "action pile", %{pid: pid, page: ap} do
    action =
      Factory.insert(:action,
        action_page: ap,
        supporter_processing_status: :new,
        processing_status: :new
      )

    n = Broadway.producer_names(Stage.Action) |> hd()
    prodpid = Process.whereis(n)

    debug("queueing... broadway name: #{n}, pid: #{inspect(prodpid)}")
    Stage.Action.process(action)

    :timer.sleep(10_000)
  end

  test "coalition action processing", %{org: lead, partners: pts} do
    num_pts = length(pts)

    action_opts = [processing_status: :new, supporter_processing_status: :new]

    IO.inspect("lead id is #{lead.id}")

    1..1000
    |> Enum.map(fn i ->
      partner = Enum.at(pts, rem(i, num_pts))

      Factory.insert(:action, [action_page: partner[:page]] ++ action_opts)
    end)
    |> Enum.each(&Stage.Action.process/1)

    :timer.sleep(10_000)
  end
end
