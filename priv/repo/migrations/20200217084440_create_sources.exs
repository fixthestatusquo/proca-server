defmodule Proca.Repo.Migrations.CreateSources do
  use Ecto.Migration

  def change do
    create table(:sources) do
      add :source, :string, null: false
      add :medium, :string, null: false
      add :campaign, :string, null: false
      add :content, :string, null: true

      timestamps()
    end

    create unique_index(:sources, [:source, :medium, :campaign])
  end
end
