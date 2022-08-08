defmodule Proca.Repo.Migrations.AddStorageBackendToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :storage_backend_id, references(:services, on_delete: :nilify_all), null: true
    end
  end
end
