defmodule Proca.Repo.Migrations.AddLocationToSource do
  use Ecto.Migration

  def change do
    alter table(:sources) do 
      add :location, :string, null: false, default: ""
    end
    drop unique_index(:sources, [:source, :medium, :campaign, :content])
    create unique_index(:sources, [:source, :medium, :campaign, :content, :location])
  end
end
