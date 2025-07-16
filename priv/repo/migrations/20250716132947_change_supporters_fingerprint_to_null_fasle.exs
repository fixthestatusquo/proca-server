defmodule Proca.Repo.Migrations.ChangeSupportersFingerprintToNullFasle do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      modify(:fingerprint, :binary, null: false)
    end
  end
end
