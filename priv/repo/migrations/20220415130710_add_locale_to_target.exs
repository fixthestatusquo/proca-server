defmodule Proca.Repo.Migrations.AddLocaleToTarget do
  use Ecto.Migration

  def change do
    alter table(:targets) do
      add :locale, :string, null: true
    end
  end
end
