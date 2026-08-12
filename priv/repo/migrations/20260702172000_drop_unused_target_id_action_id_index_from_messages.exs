defmodule Proca.Repo.Migrations.DropUnusedTargetIdActionIdIndexFromMessages do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    drop_if_exists index(:messages, [:target_id, :action_id, :dupe_rank, :sent],
                     name: :messages_target_id_action_id_dupe_rank_sent_index,
                     concurrently: true
                   )
  end
end
