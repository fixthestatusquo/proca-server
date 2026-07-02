defmodule Proca.Repo.Migrations.AddCampaignIdIndexToTargets do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:targets, [:campaign_id], concurrently: true)
  end
end
