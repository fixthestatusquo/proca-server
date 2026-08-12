defmodule Proca.Repo.Migrations.AddMessagesActionIdIndex do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    create index(:messages, [:action_id], where: "NOT sent", concurrently: true)
  end
end
