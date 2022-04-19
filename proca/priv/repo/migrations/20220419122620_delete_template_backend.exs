defmodule Proca.Repo.Migrations.DeleteTemplateBackend do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      remove :template_backend_id
    end
  end
end
