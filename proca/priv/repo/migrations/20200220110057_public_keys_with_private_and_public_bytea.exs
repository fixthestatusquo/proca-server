defmodule Proca.Repo.Migrations.PublicKeysWithPrivateAndPublicBytea do
  use Ecto.Migration

  def change do
    alter table(:public_keys) do
      remove :key
      add :public, :bytea
      add :private, :bytea
    end
  end
end
