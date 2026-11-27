defmodule Proca.Repo.Migrations.IncreaseActionFieldsSizeLimit do
  use Ecto.Migration

  # existing rows are all under 5120, so the new, looser check is added NOT VALID:
  # it applies to new and updated actions, without scanning the whole actions table
  def up do
    execute "ALTER TABLE actions DROP CONSTRAINT max_fields_size"

    execute "ALTER TABLE actions ADD CONSTRAINT max_fields_size CHECK (pg_column_size(fields) <= 10240) NOT VALID"
  end

  def down do
    execute "ALTER TABLE actions DROP CONSTRAINT max_fields_size"

    execute "ALTER TABLE actions ADD CONSTRAINT max_fields_size CHECK (pg_column_size(fields) <= 5120) NOT VALID"
  end
end
