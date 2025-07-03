defmodule Proca.Repo.Migrations.AddCampaignStatus do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :status, CampaignStatus.type(), default: 0, null: false
    end
  end
end
