defmodule Proca.Repo.Migrations.CreateStatIndexes do
  use Ecto.Migration

  def change do
    create index(:supporters, [:action_page_id, :campaign_id, :processing_status])
    create index(:actions, [:processing_status, :action_page_id])

  end
end
