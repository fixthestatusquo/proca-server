defmodule Proca.Repo.Migrations.AddDetailsBackendToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :detail_backend_id, references(:services, on_delete: :nilify_all), null: true
    end
  end
end
