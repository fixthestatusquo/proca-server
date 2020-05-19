defmodule Proca.Repo.Migrations.AddIndexToActionsRef do
  use Ecto.Migration

  def change do
    create index(:actions, [:ref])
  end
end
