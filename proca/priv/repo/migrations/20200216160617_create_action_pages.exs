defmodule Proca.Repo.Migrations.CreateActionPages do
  use Ecto.Migration

  def change do
    create table(:action_pages) do
      add :url, :string
      add :locale, :string
      add :campaign_id, references(:campaigns, on_delete: :delete_all)

      timestamps()
    end

    create index(:action_pages, [:campaign_id])
  end
end
