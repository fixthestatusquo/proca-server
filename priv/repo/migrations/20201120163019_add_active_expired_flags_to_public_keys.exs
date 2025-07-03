defmodule Proca.Repo.Migrations.AddActiveExpiredFlagsToPublicKeys do
  use Ecto.Migration

  def up do
    alter table(:public_keys) do
      add :active, :boolean, null: false, default: false
      add :expired, :boolean, null: false, default: false
    end

    execute "UPDATE public_keys SET expired = TRUE WHERE expired_at IS NOT NULL"
    execute "UPDATE public_keys SET active = TRUE WHERE expired_at IS NULL"

    alter table(:public_keys) do
      remove :expired_at
    end
  end

  def down do
    alter table(:public_keys) do
      add :expired_at, :utc_datetime
    end

    execute "UPDATE public_keys SET expired_at = updated_at WHERE expired = TRUE"
    execute "UPDATE public_keys SET expired_at = NULL WHERE active = TRUE"

    alter table(:public_keys) do
      remove :active
      remove :expired
    end
  end
end
