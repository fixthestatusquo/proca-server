defmodule Proca.Repo.Migrations.AddTargetDupeSentIdIndexToMessages do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create_if_not_exists index(:messages, [:target_id, :dupe_rank, :sent, :id],
                           name: :messages_target_id_dupe_rank_sent_id_index,
                           concurrently: true
                         )
  end
end
