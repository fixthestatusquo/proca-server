defmodule Proca.Repo.Migrations.CreateActionsSupporterIdIndex do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:actions, [:supporter_id])
  end
end
