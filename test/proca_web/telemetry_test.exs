defmodule ProcaWeb.TelemetryTest do
  use Proca.DataCase

  import Proca.StoryFactory, only: [green_story: 0]
  alias ProcaWeb.Telemetry

  describe "count_sendable_messages/0" do
    setup do
      # green_story is a drip (pacing) campaign
      story = green_story()

      nodrip =
        Factory.insert(:campaign,
          org: story.org,
          name: "mtt-nodrip",
          title: "No Drip",
          mtt: Factory.build(:mtt_new)
        )

      nodrip_ap =
        Factory.insert(:action_page,
          org: story.org,
          campaign: nodrip,
          name: "mtt-nodrip/en",
          locale: "en"
        )

      nodrip_target = Factory.insert(:target, campaign: nodrip)

      nodrip_action =
        Factory.insert(:action,
          action_page: nodrip_ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted
        )

      Factory.insert(:message, action: nodrip_action, target: nodrip_target, dupe_rank: 0)

      drip_action =
        Factory.insert(:action,
          action_page: story.ap,
          processing_status: :delivered,
          supporter_processing_status: :accepted
        )

      [drip_target | _] = story.targets
      Factory.insert(:message, action: drip_action, target: drip_target, dupe_rank: 0)

      %{story: story, nodrip: nodrip}
    end

    test "emits sendable_messages tagged with method for both paths", %{
      story: story,
      nodrip: nodrip
    } do
      ref = make_ref()
      handler_id = "sendable-messages-#{inspect(ref)}"

      :telemetry.attach(
        handler_id,
        [:mtt, :sendable],
        fn _event, measurements, metadata, _config ->
          send(self(), {:sendable, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      Telemetry.count_sendable_messages()

      assert_receive {:sendable, %{messages: 1}, %{campaign_id: campaign_id, method: :pacing}}

      assert campaign_id == story.campaign.id

      assert_receive {:sendable, %{messages: 1}, %{campaign_id: nodrip_id, method: :throttle}}

      assert nodrip_id == nodrip.id
    end
  end

  describe "mtt.throttle.scheduler metrics" do
    test "record the four-segment scheduler events" do
      :telemetry.execute(
        [:mtt, :throttle, :scheduler, :start],
        %{pending_count: 3, count: 1},
        %{target_id: 1, campaign_id: 42, campaign_name: "c"}
      )

      :telemetry.execute(
        [:mtt, :throttle, :scheduler, :stop],
        %{duration: 123, messages_sent: 3, count: 1},
        %{target_id: 1, campaign_id: 42, campaign_name: "c", stop_reason: :all_sent}
      )

      :telemetry.execute(
        [:mtt, :throttle, :scheduler, :skip],
        %{count: 1},
        %{target_id: 1, campaign_id: 42, reason: :already_running}
      )

      Process.sleep(50)

      scrape = TelemetryMetricsPrometheus.Core.scrape()

      assert scrape =~ "mtt_throttle_scheduler_start"
      assert scrape =~ "mtt_throttle_scheduler_stop"
      assert scrape =~ "mtt_throttle_scheduler_skip"
      assert scrape =~ "mtt_throttle_scheduler_pending_count"
      assert scrape =~ "mtt_throttle_scheduler_messages_sent"
      assert scrape =~ "mtt_throttle_scheduler_duration"
    end
  end
end
