defmodule Proca.Server.MTTHourlyCronTest do
  use Proca.DataCase
  @moduletag start: [:stats]

  use Proca.TestEmailBackend

  alias Proca.Server.{MTTHourlyCron, MTTContext, MTTSupervisor}

  import Proca.StoryFactory, only: [mtt_story: 0]

  setup do
    %{targets: targets} = mtt_story()

    {:ok, _reg_pid} = Registry.start_link(keys: :unique, name: Proca.Server.MTTSchedulerRegistry)

    {:ok, sup_pid} = MTTSupervisor.start_link([])
    {:ok, cron_pid} = MTTHourlyCron.start_link([])

    %{cron_pid: cron_pid, sup_pid: sup_pid, targets: targets}
  end

  describe "MTTHourlyCron" do
    test "MTTContext queries tests", %{targets: [target | _] = targets} do
      # set max_emails per hour for 2 campaigns to 100
      Repo.update_all(from(mtt in Proca.MTT, where: mtt.campaign_id == ^target.campaign.id),
        set: [max_emails_per_hour: 100]
      )

      # get current hour in Etc/UTC timezone
      current_hour = DateTime.utc_now().hour

      default_max_emails =
        Application.get_env(:proca, Proca.Server.MTTScheduler)
        |> Access.get(:max_emails_per_hour)

      messages_ratio =
        Application.get_env(:proca, Proca.Server.MTTScheduler)
        |> Access.get(:messages_ratio_per_hour)

      # get ratio for current hour
      ratio =
        messages_ratio
        |> Access.get(current_hour)

      # like MTTHourlyCron, rank before listing: only dupe_rank 0 messages count
      assert {:ok, _} = MTTContext.dupe_rank()
      active_targets = MTTContext.get_active_targets()

      active_targets
      |> Enum.each(fn target ->
        max_emails = MTTContext.max_emails_per_hour(target.campaign)

        target_emails_per_hour =
          ((target.campaign.mtt.max_emails_per_hour || default_max_emails) * ratio)
          |> trunc()

        assert is_integer(max_emails) or is_atom(max_emails)
        assert max_emails in [target_emails_per_hour, :all]
      end)

      assert length(targets) == length(active_targets)
    end

    test "a target with several usable emails is returned once", %{targets: [target | _]} do
      MTTContext.dupe_rank()

      Repo.insert!(%Proca.TargetEmail{
        target_id: target.id,
        email: "second-#{target.id}@example.org",
        email_status: :active
      })

      ids = MTTContext.get_active_targets() |> Enum.map(& &1.id)

      assert Enum.count(ids, &(&1 == target.id)) == 1
      assert ids == Enum.uniq(ids)
    end

    test "targets without pending live messages are not returned", %{
      targets: [done, test_only | rest]
    } do
      MTTContext.dupe_rank()

      # every message of `done` already sent
      Repo.update_all(from(m in Proca.Action.Message, where: m.target_id == ^done.id),
        set: [sent: true]
      )

      # `test_only` has only testing actions (these go via deliver_test_mails)
      test_action_ids =
        from(m in Proca.Action.Message, where: m.target_id == ^test_only.id, select: m.action_id)

      Repo.update_all(from(a in Proca.Action, where: a.id in subquery(test_action_ids)),
        set: [testing: true]
      )

      active_ids = MTTContext.get_active_targets() |> Enum.map(& &1.id) |> MapSet.new()

      refute done.id in active_ids
      refute test_only.id in active_ids
      assert MapSet.new(rest, & &1.id) |> MapSet.subset?(active_ids)
    end

    test "starts one MTT scheduler process per active target", %{
      cron_pid: cron_pid,
      sup_pid: sup_pid,
      targets: targets
    } do
      assert Process.alive?(cron_pid)
      assert Process.alive?(sup_pid)

      send(cron_pid, :run_mtt)

      :timer.sleep(2000)

      # Check supervisor children
      children = DynamicSupervisor.count_children(sup_pid)

      assert children.workers == targets |> Enum.count()

      # Clean up
      GenServer.stop(cron_pid)
      DynamicSupervisor.stop(sup_pid)
    end
  end
end
