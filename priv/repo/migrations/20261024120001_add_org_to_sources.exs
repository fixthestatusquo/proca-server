defmodule Proca.Repo.Migrations.AddOrgToSources do
  @moduledoc """
  Scope tracking sources by org.

  A source row is created per (utm codes + location) and was shared by every org
  that happened to use the same tuple. Give each source an owner and split the
  rows that are in use by more than one org.

  org_id stays nullable on purpose: old app versions insert NULL and Postgres
  treats NULLs as distinct in a unique index, so during a rolling deploy those
  inserts create duplicates rather than failing. A follow up migration can set
  NOT NULL once every node runs the new code.
  """
  use Ecto.Migration

  def up do
    alter table(:sources) do
      add :org_id, references(:orgs, on_delete: :nilify_all)
    end

    # org(s) that actually use each source row, via actions and supporters
    execute """
    CREATE TEMPORARY TABLE source_orgs AS
      SELECT a.source_id AS id, ap.org_id
        FROM actions a JOIN action_pages ap ON ap.id = a.action_page_id
       WHERE a.source_id IS NOT NULL
      UNION
      SELECT su.source_id, ap.org_id
        FROM supporters su JOIN action_pages ap ON ap.id = su.action_page_id
       WHERE su.source_id IS NOT NULL
    """

    execute "CREATE INDEX ON source_orgs (id)"

    # rows used by one org belong to it; shared rows keep the lowest org
    execute """
    UPDATE sources s SET org_id = u.org_id
      FROM (SELECT id, min(org_id) AS org_id FROM source_orgs GROUP BY id) u
     WHERE s.id = u.id AND s.org_id IS NULL
    """

    # the new key, before the copies so that re-inserting is idempotent
    drop unique_index(:sources, [:source, :medium, :campaign, :content, :location])
    create unique_index(:sources, [:org_id, :source, :medium, :campaign, :content, :location])

    # every other org using a shared row gets its own copy
    execute """
    INSERT INTO sources (source, medium, campaign, content, location, org_id, inserted_at, updated_at)
    SELECT s.source, s.medium, s.campaign, s.content, s.location, so.org_id, now(), now()
      FROM sources s JOIN source_orgs so ON so.id = s.id
     WHERE s.org_id IS DISTINCT FROM so.org_id
    ON CONFLICT DO NOTHING
    """

    # and the actions and supporters move to the copy of their own org
    execute """
    UPDATE actions a SET source_id = c.id
      FROM sources s, sources c, action_pages ap
     WHERE s.id = a.source_id
       AND ap.id = a.action_page_id
       AND s.org_id IS DISTINCT FROM ap.org_id
       AND c.org_id = ap.org_id
       AND c.source = s.source AND c.medium = s.medium AND c.campaign = s.campaign
       AND c.content = s.content AND c.location = s.location
    """

    execute """
    UPDATE supporters su SET source_id = c.id
      FROM sources s, sources c, action_pages ap
     WHERE s.id = su.source_id
       AND ap.id = su.action_page_id
       AND s.org_id IS DISTINCT FROM ap.org_id
       AND c.org_id = ap.org_id
       AND c.source = s.source AND c.medium = s.medium AND c.campaign = s.campaign
       AND c.content = s.content AND c.location = s.location
    """

    execute "DROP TABLE source_orgs"
  end

  def down do
    raise Ecto.MigrationError,
      message: "AddOrgToSources is irreversible: merged sources are duplicated"
  end
end
