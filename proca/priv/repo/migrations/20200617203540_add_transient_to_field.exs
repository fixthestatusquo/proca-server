defmodule Proca.Repo.Migrations.AddTransientToField do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      add :transient, :boolean, default: false, null: false
    end
  end
end
