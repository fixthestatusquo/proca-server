defmodule Proca.Repo.Migrations.AddDupeRankIndexToSupporters do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:supporters, [:dupe_rank], name: :supporters_dupe_rank_index)
  end
end
