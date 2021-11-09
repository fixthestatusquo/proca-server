defmodule Proca.Repo.Migrations.CreateTargets do
  use Ecto.Migration

  def change do
    create table(:targets, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :external_id, :string, null: false
      add :area, :string
      add :name, :string
      add :fields, :map, null: false, default: "{}"
      add :campaign_id, references(:campaigns, on_delete: :nothing)

      timestamps()
    end

    create unique_index(:targets, [:external_id])
  end
end
