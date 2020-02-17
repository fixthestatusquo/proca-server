defmodule Proca.Repo.Migrations.CreatePublicKeys do
  use Ecto.Migration

  def change do
    create table(:public_keys) do
      add :name, :string, null: false
      add :key, :string, null: false
      add :org_id, references(:orgs, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:public_keys, [:org_id])
  end
end
