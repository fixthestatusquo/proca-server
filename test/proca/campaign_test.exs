defmodule Proca.CampaignTest do
  use Proca.DataCase
  import Proca.StoryFactory, only: [red_story: 0]
  alias Proca.Campaign

  setup do
    red_story()
  end

  test "accepts valid start and end", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-dates",
        title: "Test Dates",
        contact_schema: :basic,
        org: org,
        start: ~D[2026-01-01],
        end: ~D[2026-12-31]
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
        start: nil,
        end: nil
      })

    assert changeset.valid?
  end

  test "accepts only start", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-start-only",
        title: "Test Start Only",
        contact_schema: :basic,
        org: org,
        start: ~D[2026-01-01],
        end: nil
      })

    assert changeset.valid?
  end

  test "accepts only end", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-end-only",
        title: "Test End Only",
        contact_schema: :basic,
        org: org,
        start: nil,
        end: ~D[2026-12-31]
      })

    assert changeset.valid?
  end

  test "rejects end before start", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-invalid-dates",
        title: "Test Invalid Dates",
        contact_schema: :basic,
        org: org,
        start: ~D[2026-12-31],
        end: ~D[2026-01-01]
      })

    refute changeset.valid?
    assert %{end: ["must be after start"]} = errors_on(changeset)
  end

  test "rejects equal start and end", %{red_org: org} do
    changeset =
      Campaign.changeset(%Campaign{}, %{
        name: "test-equal-dates",
        title: "Test Equal Dates",
        contact_schema: :basic,
        org: org,
        start: ~D[2026-06-01],
        end: ~D[2026-06-01]
      })

    refute changeset.valid?
    assert %{end: ["must be after start"]} = errors_on(changeset)
  end

  test "updates campaign with valid dates", %{red_campaign: campaign} do
    changeset =
      Campaign.changeset(campaign, %{
        start: ~D[2026-01-01],
        end: ~D[2026-12-31]
      })

    assert changeset.valid?
  end

  test "updates campaign with invalid dates", %{red_campaign: campaign} do
    changeset =
      Campaign.changeset(campaign, %{
        start: ~D[2026-12-31],
        end: ~D[2026-01-01]
      })

    refute changeset.valid?
    assert %{end: ["must be after start"]} = errors_on(changeset)
  end
end
