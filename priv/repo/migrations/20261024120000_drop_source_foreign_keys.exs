defmodule Proca.Repo.Migrations.DropSourceForeignKeys do
  @moduledoc """
  Nothing queries actions or supporters by source_id, and no code deletes a
  source, so the foreign keys only cost a parent lookup and a KEY SHARE lock on
  the (deduplicated, therefore hot) sources row for every action insert, and
  they would make a future per-org source purge a seq scan on both tables.

  Dropping them also means the org backfill does not need an index on
  source_id: it scans each table once instead of paying a permanent write cost
  on the hottest insert path.
  """
  use Ecto.Migration

  def up do
    execute "ALTER TABLE actions DROP CONSTRAINT IF EXISTS actions_source_id_fkey"
    execute "ALTER TABLE supporters DROP CONSTRAINT IF EXISTS supporters_source_id_fkey"
  end

  def down do
    execute "ALTER TABLE actions ADD CONSTRAINT actions_source_id_fkey FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL NOT VALID"
    execute "ALTER TABLE supporters ADD CONSTRAINT supporters_source_id_fkey FOREIGN KEY (source_id) REFERENCES sources(id) ON DELETE SET NULL NOT VALID"
  end
end
