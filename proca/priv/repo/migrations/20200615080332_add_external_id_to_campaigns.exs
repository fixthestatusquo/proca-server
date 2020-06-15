defmodule Proca.Repo.Migrations.AddExternalIdToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :external_id, :integer, null: true
    end

    create unique_index(:campaigns, [:org_id, :external_id])
  end
end
