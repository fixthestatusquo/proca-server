defmodule Proca.Campaign.BackfillDates do
  @moduledoc """
  Backfill campaign start/end dates from action data.

  Sets start_date from the earliest non-test action per campaign.
  Sets end_date from the latest non-test action for campaigns with no activity in the last month.

  Does not change campaign status.
  Safe to run repeatedly — only fills NULL dates.
  """

  alias Proca.Repo

  def run do
    %{num_rows: start_count} =
      Ecto.Adapters.SQL.query!(Repo, """
      UPDATE campaigns
      SET start_date = sub.first_action
      FROM (
        SELECT campaign_id, MIN(inserted_at)::date AS first_action
        FROM actions
        WHERE testing = false
        GROUP BY campaign_id
      ) AS sub
      WHERE campaigns.id = sub.campaign_id
        AND campaigns.start_date IS NULL
      """)

    %{num_rows: end_count} =
      Ecto.Adapters.SQL.query!(Repo, """
      UPDATE campaigns
      SET end_date = sub.last_action
      FROM (
        SELECT campaign_id,
               MAX(inserted_at)::date AS last_action
        FROM actions
        WHERE testing = false
        GROUP BY campaign_id
        HAVING MAX(inserted_at) < NOW() - INTERVAL '1 month'
      ) AS sub
      WHERE campaigns.id = sub.campaign_id
        AND campaigns.end_date IS NULL
      """)

    IO.puts("Backfilled start_date for #{start_count}, end_date for #{end_count} campaigns")
  end
end
