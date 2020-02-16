defmodule Proca.Repo.Migrations.CreateCampaigns do
  use Ecto.Migration

  def change do
    create table(:campaigns) do
      add :name, :string
      add :title, :string
      add :org_id, references(:orgs, on_delete: :nilify_all)

      timestamps()
    end

  end
end
