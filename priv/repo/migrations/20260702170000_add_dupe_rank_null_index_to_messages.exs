defmodule Proca.Repo.Migrations.AddDupeRankNullIndexToMessages do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true
  def change do
    create index(:messages, [:action_id],
             where: "dupe_rank IS NULL",
             name: :messages_dupe_rank_null_index,
             concurrently: true)
  end
end
