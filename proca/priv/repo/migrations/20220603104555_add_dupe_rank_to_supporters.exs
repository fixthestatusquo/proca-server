defmodule Proca.Repo.Migrations.AddDupeRankToSupporters do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :dupe_rank, :integer, null: true
    end
  end
end
