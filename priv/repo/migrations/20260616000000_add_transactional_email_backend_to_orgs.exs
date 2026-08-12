defmodule Proca.Repo.Migrations.AddTransactionalEmailBackendToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :transactional_email_backend_id, references(:services, on_delete: :nilify_all),
        null: true
    end
  end
end
