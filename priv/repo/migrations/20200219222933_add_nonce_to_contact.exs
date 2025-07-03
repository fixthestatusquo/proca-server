defmodule Proca.Repo.Migrations.AddNonceToContact do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :encrypted_nonce, :bytea
    end
  end
end
