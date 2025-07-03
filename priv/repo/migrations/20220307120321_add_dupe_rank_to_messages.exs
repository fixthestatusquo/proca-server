defmodule Proca.Repo.Migrations.AddDupeRankToMessages do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :dupe_rank, :integer, null: true
    end
  end
end
