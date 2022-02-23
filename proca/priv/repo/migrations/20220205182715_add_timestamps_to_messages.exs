defmodule Proca.Repo.Migrations.AddTimestampsToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :updated_at, :naive_datetime, null: true
    end

    execute "update messages set updated_at = NOW()", ""

    alter table(:messages) do
      modify :updated_at, :naive_datetime, null: false
    end
  end
end
