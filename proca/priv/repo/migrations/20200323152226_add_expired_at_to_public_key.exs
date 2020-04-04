defmodule Proca.Repo.Migrations.AddExpiredAtToPublicKey do
  use Ecto.Migration

  def change do
    alter table (:public_keys) do
      add :expired_at, :utc_datetime, null: true
    end
  end
end
