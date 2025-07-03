defmodule Proca.Repo.Migrations.SourcesExpandUniqueIndexToContent do
  use Ecto.Migration

  def change do
    drop unique_index(:sources, [:source, :medium, :campaign])
    create unique_index(:sources, [:source, :medium, :campaign, :content])
  end
end
