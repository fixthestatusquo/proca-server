defmodule Proca.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :name, :string, null: false
      add :title, :string, null: false
      add :org_id, references(:orgs, on_delete: :nilify_all)

      timestamps()
    end

  end
end
