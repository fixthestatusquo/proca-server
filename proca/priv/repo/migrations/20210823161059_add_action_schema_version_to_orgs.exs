defmodule Proca.Repo.Migrations.AddActionSchemaVersionToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :action_schema_version, :smallint, null: false, default: 2
    end

    execute "UPDATE orgs SET action_schema_version = 1", ""
  end
end
