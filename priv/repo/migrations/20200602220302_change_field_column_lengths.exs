defmodule Proca.Repo.Migrations.ChangeFieldColumnLengths do
  use Ecto.Migration

  def change do
    alter table(:fields) do
      modify :value, :text, null: false
    end
  end
end
