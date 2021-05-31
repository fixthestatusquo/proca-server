defmodule Proca.Repo.Migrations.AddUniqueIndexToCampaignName do
  use Ecto.Migration

  def change do
    create unique_index(:campaigns, [:name])

  end
end
