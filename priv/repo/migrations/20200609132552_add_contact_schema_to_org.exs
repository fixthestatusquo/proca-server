defmodule Proca.Repo.Migrations.AddContactSchemaToOrg do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :contact_schema, ContactSchema.type(), default: 0, null: false
    end
  end
end
