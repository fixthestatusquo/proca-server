defmodule Proca.Repo.Migrations.CreateContactSignatures do
  use Ecto.Migration

  def change do
    create table(:contact_signatures, primary_key: false) do
      add :contact_id, references(:contacts, on_delete: :nothing), null: false
      add :signature_id, references(:signatures, on_delete: :nothing), null: false

      timestamps()
    end

    create index(:contact_signatures, [:contact_id])
    create index(:contact_signatures, [:signature_id])
    create(
      unique_index(:contact_signatures, [:contact_id, :signature_id], name: :contact_id_signature_id_unique_index)
    )
  end
end
