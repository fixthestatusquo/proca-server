defmodule Proca.Repo.Migrations.CreatePublicKeys do
  use Ecto.Migration

  def change do
    create table(:public_keys) do
      add :name, :string
      add :key, :string
      add :org_id, references(:orgs, on_delete: :nothing)

      timestamps()
    end

    create index(:public_keys, [:org_id])
  end
end
