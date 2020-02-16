defmodule Proca.Repo.Migrations.CreateSignatures do
  use Ecto.Migration

  def change do
    create table(:signatures) do
      add :campaign_id, references(:campaigns, on_delete: :delete_all)

      timestamps()
    end

    create index(:signatures, [:campaign_id])
  end
end
