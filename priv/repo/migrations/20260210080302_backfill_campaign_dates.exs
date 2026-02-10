defmodule Proca.Repo.Migrations.BackfillCampaignDates do
  use Ecto.Migration

  def up do
    # Set start_date from the earliest non-test action per campaign
    execute("""
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

    # Set end_date and close campaigns that have no non-test action in the last month
    execute("""
    UPDATE campaigns
    SET end_date = sub.last_action,
        status = 2
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
  end

  def down do
    execute("UPDATE campaigns SET start_date = NULL, end_date = NULL, status = 1")
  end
end
