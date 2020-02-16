defmodule Proca.Repo.Migrations.CreateContactSignautres do
  use Ecto.Migration

  def change do
    create table(:contact_signautres, primary_key: false) do
      add :contact_id, references(:contacts, on_delete: :delete_all)
      add :signsature_id, references(:signatures, on_delete: :delete_all)

      timestamps()
    end

    create index(:contact_signautres, [:contact_id])
    create index(:contact_signautres, [:contact_id])
  end
end
