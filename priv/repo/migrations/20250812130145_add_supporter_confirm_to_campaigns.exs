defmodule Proca.Repo.Migrations.AddSupporterConfirmToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :supporter_confirm, :boolean, default: false, null: false
      add :supporter_confirm_template, :string, null: true
    end
  end
end
