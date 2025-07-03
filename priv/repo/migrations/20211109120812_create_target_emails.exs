defmodule Proca.Repo.Migrations.CreateTargetEmails do
  use Ecto.Migration

  def change do
    create table(:target_emails) do
      add :email, :string
      add :target_id, references(:targets, type: :uuid, on_delete: :nothing)

      timestamps()
    end

    create index(:target_emails, [:target_id])
  end
end
