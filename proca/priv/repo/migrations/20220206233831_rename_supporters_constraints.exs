defmodule Proca.Repo.Migrations.RenameSupportersConstraints do
  use Ecto.Migration

  def change do
    # Indexes
    for {_table, constraint} <- [supporters: "pkey", supporters: "campaign_id_index"] do
      up = "ALTER INDEX signatures_#{constraint} RENAME TO supporters_#{constraint}"
      down = "ALTER INDEX supporters_#{constraint} RENAME TO signatures_#{constraint}"
      execute up, down
    end

    # FK constraints
    for {table, constraint} <- [supporters: "source_id_fkey"] do
      up =
        "ALTER TABLE #{table} RENAME CONSTRAINT signatures_#{constraint} TO supporters_#{constraint}"

      down =
        "ALTER TABLE #{table} RENAME CONSTRAINT supporters_#{constraint} TO signatures_#{constraint}"

      execute up, down
    end
  end
end
