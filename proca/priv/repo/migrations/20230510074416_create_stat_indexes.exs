defmodule Proca.Repo.Migrations.CreateStatIndexes do
  use Ecto.Migration

  def change do
    create index(:supporters, [:action_page_id])
    create index(:supporters, [:campaign_id])
    create index(:supporters, [:processing_status])
    create index(:actions, [:processing_status])
    create index(:actions, [:action_page_id])
  end
end
