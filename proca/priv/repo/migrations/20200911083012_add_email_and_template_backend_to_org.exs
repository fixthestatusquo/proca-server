defmodule Proca.Repo.Migrations.AddEmailAndTemplateBackendToOrg do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :email_backend_id, references(:services, on_delete: :nilify_all), null: true
      add :template_backend_id, references(:services, on_delete: :nilify_all), null: true
    end
  end
end
