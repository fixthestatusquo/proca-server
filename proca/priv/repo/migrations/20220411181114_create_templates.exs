defmodule Proca.Repo.Migrations.CreateTemplates do
  use Ecto.Migration

  def change do
    create table(:email_templates) do
      add :name, :string, null: false
      add :locale, :string, null: false
      add :subject, :string, null: false
      add :html, :string, null: false
      add :text, :string, null: true
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
    end

    create unique_index(:email_templates, [:org_id, :name, :locale])
  end
end
