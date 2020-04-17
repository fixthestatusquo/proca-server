defmodule Proca.Repo.Migrations.AddFingerprintToSignature do
  use Ecto.Migration

  def change do
    alter table (:signatures) do
      add :fingerprint, :bytea
    end
  end
end
