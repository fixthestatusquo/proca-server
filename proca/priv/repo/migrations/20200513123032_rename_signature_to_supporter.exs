defmodule Proca.Repo.Migrations.RenameSignatureToSupporter do
  use Ecto.Migration

  def change do
    rename table(:signatures), to: table(:supporters)
    rename table(:contact_signatures), to: table(:supporter_contacts)
    rename table(:supporter_contacts), :signature_id, to: :supporter_id

    create index(:supporters, [:fingerprint])

  end
end
