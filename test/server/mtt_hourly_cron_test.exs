defmodule Proca.Server.MTTHourlyCronTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Server.{MTTHourlyCron, MTTContext, MTTSupervisor}

  import Proca.StoryFactory, only: [mtt_story: 0]

  setup do
    %{targets: targets} = mtt_story()

    {:ok, sup_pid} = MTTSupervisor.start_link([])
    {:ok, cron_pid} = MTTHourlyCron.start_link([])

    %{cron_pid: cron_pid, sup_pid: sup_pid, targets: targets}
  end

  describe "MTTHourlyCron" do
    test "queries active targets and computes hourly limits", %{targets: [target | _] = targets} do
      Repo.update_all(from(mtt in Proca.MTT, where: mtt.campaign_id == ^target.campaign.id),
        set: [max_emails_per_hour: 100]
      )

      current_hour = DateTime.utc_now().hour

      default_max_emails =
        Application.get_env(:proca, Proca.Server.MTTScheduler)
        |> Access.get(:max_emails_per_hour)

      messages_ratio =
        Application.get_env(:proca, Proca.Server.MTTScheduler)
        |> Access.get(:messages_ratio_per_hour)

      ratio = messages_ratio |> Access.get(current_hour)

      active_targets = MTTContext.get_active_targets()

      active_targets
      |> Enum.each(fn active_target ->
        max_emails = MTTContext.max_emails_per_hour(active_target.campaign)

        target_emails_per_hour =
          ((active_target.campaign.mtt.max_emails_per_hour || default_max_emails) * ratio)
          |> trunc()

        assert is_integer(max_emails) or is_atom(max_emails)
        assert max_emails in [target_emails_per_hour, :all]
      end)

      assert length(targets) == length(active_targets)
      assert {:ok, _} = MTTContext.dupe_rank()
    end

    test "starts one scheduler process per active target", %{
      cron_pid: cron_pid,
      sup_pid: sup_pid,
      targets: targets
    } do
      assert Process.alive?(cron_pid)
      assert Process.alive?(sup_pid)

      send(cron_pid, :run_mtt)

      :timer.sleep(2000)

      children = DynamicSupervisor.count_children(sup_pid)

      assert children.workers == Enum.count(targets)

      GenServer.stop(cron_pid)
      DynamicSupervisor.stop(sup_pid)
    end
  end
end
