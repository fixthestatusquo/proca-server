defmodule Proca.Repo.Migrations.AddTargetIdIndexToMessages do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:messages, [:target_id])
  end
end
