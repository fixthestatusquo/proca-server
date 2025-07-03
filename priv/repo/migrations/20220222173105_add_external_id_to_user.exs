defmodule Proca.Repo.Migrations.AddExternalIdToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :external_id, :string, null: true
    end

    create unique_index(:users, [:external_id])
  end
end
