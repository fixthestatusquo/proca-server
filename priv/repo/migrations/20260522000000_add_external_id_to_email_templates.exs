defmodule Proca.Repo.Migrations.AddExternalIdToEmailTemplates do
  use Ecto.Migration

  def change do
    alter table(:email_templates) do
      add :external_id, :string, null: true
    end
  end
end
