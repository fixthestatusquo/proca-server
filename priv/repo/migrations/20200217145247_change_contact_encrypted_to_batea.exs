defmodule Proca.Repo.Migrations.ChangeContactEncryptedToBatea do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      remove :encrypted
      add :encrypted, :bytea, null: true
    end
  end
end
