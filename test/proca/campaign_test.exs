defmodule Proca.CampaignTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Campaign

  setup do
    red_story()
  end

  test "accepts valid start_date and end_date", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-dates",
        title: "Test Dates",
        contact_schema: :basic,
        org: org,
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31]
      })

    assert changeset.valid?
  end

  test "accepts nil dates", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-nil-dates",
        title: "Test Nil Dates",
        contact_schema: :basic,
        org: org,
        start_date: nil,
        end_date: nil
      })

    assert changeset.valid?
  end

  test "accepts only start_date", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-start-only",
        title: "Test Start Only",
        contact_schema: :basic,
        org: org,
        start_date: ~D[2026-01-01],
        end_date: nil
      })

    assert changeset.valid?
  end

  test "accepts only end_date", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-end-only",
        title: "Test End Only",
        contact_schema: :basic,
        org: org,
        start_date: nil,
        end_date: ~D[2026-12-31]
      })

    assert changeset.valid?
  end

  test "rejects end_date before start_date", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-invalid-dates",
        title: "Test Invalid Dates",
        contact_schema: :basic,
        org: org,
        start_date: ~D[2026-12-31],
        end_date: ~D[2026-01-01]
      })

    refute changeset.valid?
    assert %{end_date: ["must be after start_date"]} = errors_on(changeset)
  end

  test "rejects equal start_date and end_date", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-equal-dates",
        title: "Test Equal Dates",
        contact_schema: :basic,
        org: org,
        start_date: ~D[2026-06-01],
        end_date: ~D[2026-06-01]
      })

    refute changeset.valid?
    assert %{end_date: ["must be after start_date"]} = errors_on(changeset)
  end

  test "updates campaign with valid dates", %{red_campaign: campaign} do
    changeset =
      Campaign.changeset(campaign, %{
        start_date: ~D[2026-01-01],
        end_date: ~D[2026-12-31]
      })

    assert changeset.valid?
  end

  test "updates campaign with invalid dates", %{red_campaign: campaign} do
    changeset =
      Campaign.changeset(campaign, %{
        start_date: ~D[2026-12-31],
        end_date: ~D[2026-01-01]
      })

    refute changeset.valid?
    assert %{end_date: ["must be after start_date"]} = errors_on(changeset)
  end
end
