defmodule Proca.Repo.Migrations.AddDuplicateTemplateToActionPages do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      add :duplicate_template, :string, null: true
    end
  end
end
