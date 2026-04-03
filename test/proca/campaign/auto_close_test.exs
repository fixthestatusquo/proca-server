defmodule Proca.Campaign.AutoCloseTest do
  use Proca.DataCase, async: true

  import Ecto.Changeset
  import Ecto.Query

  alias Proca.{Action, Campaign, Factory, Repo}
  alias Proca.Campaign.AutoClose

  import Proca.StoryFactory, only: [blue_story: 0]

  @old_timestamp ~N[2020-01-01 00:00:00]

  test "closes live campaign with old actions and backfills dates" do
    %{pages: [page], campaign: campaign} = blue_story()
    action = insert_action(page)
    age_action(action, @old_timestamp)
    age_campaign(campaign, @old_timestamp)

    assert {:ok, result} = AutoClose.run(3)
    assert result.closed == 1
    assert result.with_actions == 1

    campaign = Repo.get!(Campaign, campaign.id)
    assert campaign.status == :closed
    assert campaign.start != nil
    assert campaign.end != nil
  end

  test "does not close live campaign with recent actions" do
    %{pages: [page], campaign: campaign} = blue_story()
    _action = insert_action(page)

    assert {:ok, result} = AutoClose.run(3)
    assert result.closed == 0

    campaign = Repo.get!(Campaign, campaign.id)
    assert campaign.status == :live
  end

  test "does not touch already closed campaigns" do
    %{pages: [page], campaign: campaign} = blue_story()
    action = insert_action(page)
    age_action(action, @old_timestamp)
    Repo.update!(change(campaign, status: :closed, end: ~D[2020-01-01]))

    assert {:ok, result} = AutoClose.run(3)
    assert result.closed == 0
  end

  test "does not touch draft campaigns" do
    %{pages: [page], campaign: campaign} = blue_story()
    action = insert_action(page)
    age_action(action, @old_timestamp)
    Repo.update!(change(campaign, status: :draft))
    age_campaign(campaign, @old_timestamp)

    assert {:ok, result} = AutoClose.run(3)
    assert result.closed == 0
  end

  test "closes live campaign with zero actions when campaign is old" do
    %{campaign: campaign} = blue_story()
    age_campaign(campaign, @old_timestamp)

    assert {:ok, result} = AutoClose.run(3)
    assert result.closed == 1
    assert result.without_actions == 1

    campaign = Repo.get!(Campaign, campaign.id)
    assert campaign.status == :closed
    assert campaign.start == nil
    assert campaign.end == nil
  end

  test "does not overwrite existing dates" do
    %{pages: [page], campaign: campaign} = blue_story()
    action = insert_action(page)
    age_action(action, @old_timestamp)

    manual_start = ~D[2019-06-01]
    manual_end = ~D[2020-06-01]
    Repo.update!(change(campaign, start: manual_start, end: manual_end))
    age_campaign(campaign, @old_timestamp)

    assert {:ok, _} = AutoClose.run(3)

    campaign = Repo.get!(Campaign, campaign.id)
    assert campaign.status == :closed
    assert campaign.start == manual_start
    assert campaign.end == manual_end
  end

  test "dry run reports without modifying" do
    %{pages: [page], campaign: campaign} = blue_story()
    action = insert_action(page)
    age_action(action, @old_timestamp)
    age_campaign(campaign, @old_timestamp)

    assert {:ok, result} = AutoClose.run(3, dry_run: true)
    assert result.dry_run
    assert result.would_close == 1

    campaign = Repo.get!(Campaign, campaign.id)
    assert campaign.status == :live
  end

  defp insert_action(action_page) do
    Factory.insert(:action,
      action_page: action_page,
      supporter_processing_status: :accepted,
      processing_status: :delivered
    )
  end

  defp age_action(action, inserted_at) do
    Repo.update_all(from(a in Action, where: a.id == ^action.id),
      set: [inserted_at: inserted_at, updated_at: inserted_at]
    )
  end

  defp age_campaign(campaign, inserted_at) do
    Repo.update_all(from(c in Campaign, where: c.id == ^campaign.id),
      set: [inserted_at: inserted_at, updated_at: inserted_at]
    )
  end
end
