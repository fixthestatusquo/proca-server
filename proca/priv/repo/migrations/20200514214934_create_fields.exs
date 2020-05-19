defmodule Proca.Repo.Migrations.CreateFields do
  use Ecto.Migration

  def change do
    create table(:fields) do
      add :key, :string, null: false
      add :value, :string, null: false
      add :action_id, references(:actions, on_delete: :delete_all), null: false
    end

    create index(:fields, [:key])
  end
end
