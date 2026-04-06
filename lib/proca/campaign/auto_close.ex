defmodule Proca.Campaign.AutoClose do
  @moduledoc """
  Automatically close stale live campaigns and backfill their start/end dates.

  A campaign is considered stale when all of its non-test actions are older than
  the given inactivity threshold (default: 3 months). Campaigns with zero actions
  are closed if the campaign itself was created before the threshold.

  Does not touch draft, closed, or ignored campaigns.
  Safe to run repeatedly.
  """

  alias Proca.Repo

  @default_months 3

  def default_months, do: @default_months

  def run(months \\ @default_months, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)

    if dry_run do
      count = count_candidates(months)
      {:ok, %{dry_run: true, would_close: count}}
    else
      {with_actions, without_actions} = close_campaigns(months)
      {:ok, %{closed: with_actions + without_actions, with_actions: with_actions, without_actions: without_actions}}
    end
  end

  defp count_candidates(months) do
    %{num_rows: _, rows: [[with_actions]]} =
      Ecto.Adapters.SQL.query!(Repo, """
      SELECT COUNT(*) FROM campaigns
      WHERE campaigns.status = 1
        AND campaigns.id IN (
          SELECT campaign_id FROM actions
          WHERE testing = false
          GROUP BY campaign_id
          HAVING MAX(inserted_at) < NOW() - make_interval(months => $1)
        )
      """, [months])

    %{num_rows: _, rows: [[without_actions]]} =
      Ecto.Adapters.SQL.query!(Repo, """
      SELECT COUNT(*) FROM campaigns
      WHERE campaigns.status = 1
        AND NOT EXISTS (
          SELECT 1 FROM actions WHERE actions.campaign_id = campaigns.id AND testing = false
        )
        AND campaigns.inserted_at < NOW() - make_interval(months => $1)
      """, [months])

    with_actions + without_actions
  end

  defp close_campaigns(months) do
    %{num_rows: with_actions} =
      Ecto.Adapters.SQL.query!(Repo, """
      UPDATE campaigns
      SET status = 2,
          start_date = COALESCE(campaigns.start_date, sub.first_action),
          end_date = COALESCE(campaigns.end_date, sub.last_action)
      FROM (
        SELECT campaign_id,
               MIN(inserted_at)::date AS first_action,
               MAX(inserted_at)::date AS last_action
        FROM actions
        WHERE testing = false
        GROUP BY campaign_id
        HAVING MAX(inserted_at) < NOW() - make_interval(months => $1)
      ) AS sub
      WHERE campaigns.id = sub.campaign_id
        AND campaigns.status = 1
      """, [months])

    %{num_rows: without_actions} =
      Ecto.Adapters.SQL.query!(Repo, """
      UPDATE campaigns
      SET status = 2
      WHERE campaigns.status = 1
        AND NOT EXISTS (
          SELECT 1 FROM actions WHERE actions.campaign_id = campaigns.id AND testing = false
        )
        AND campaigns.inserted_at < NOW() - make_interval(months => $1)
      """, [months])

    {with_actions, without_actions}
  end
end
