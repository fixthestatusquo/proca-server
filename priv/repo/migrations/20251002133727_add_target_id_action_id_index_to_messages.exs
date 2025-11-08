defmodule Proca.Repo.Migrations.AddTargetIdActionIdIndexToMessages do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:messages, [:target_id, :action_id, :dupe_rank, :sent])
  end
end
