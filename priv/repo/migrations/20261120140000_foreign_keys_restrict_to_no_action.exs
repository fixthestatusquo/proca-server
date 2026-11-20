defmodule Proca.Repo.Migrations.ForeignKeysRestrictToNoAction do
  @moduledoc """
  Postgres 18 reports a delete blocked by an `ON DELETE RESTRICT` foreign key as
  `restrict_violation` (23001) instead of `foreign_key_violation` (23503).
  ecto_sql only maps 23503, so `foreign_key_constraint/3` stops catching it and
  deletes that should return "has messages" / "has action pages" crash instead.

  `NO ACTION` blocks the same deletes (none of these keys are deferrable) but is
  reported as 23503 on every Postgres version.

  Each key is swapped in a single `ALTER TABLE` (drop + add `NOT VALID`, instant,
  enforced from then on), then validated separately: `VALIDATE CONSTRAINT` scans
  the table without blocking inserts/updates, so big tables (actions,
  supporters) stay writable during the deploy. Hence no DDL transaction.
  Re-running after a partial failure is safe.
  """
  use Ecto.Migration

  @disable_ddl_transaction true

  # {table, constraint, column, referenced table}
  @keys [
    {"messages", "messages_target_id_fkey", "target_id", "targets"},
    {"action_pages", "action_pages_org_id_fkey", "org_id", "orgs"},
    {"action_pages", "action_pages_campaign_id_fkey", "campaign_id", "campaigns"},
    {"actions", "actions_action_page_id_fkey", "action_page_id", "action_pages"},
    {"supporters", "supporters_action_page_id_fkey", "action_page_id", "action_pages"},
    {"supporters", "supporters_campaign_id_fkey", "campaign_id", "campaigns"}
  ]

  def up, do: set_on_delete("NO ACTION")

  def down, do: set_on_delete("RESTRICT")

  defp set_on_delete(rule) do
    for {table, name, column, ref} <- @keys do
      execute """
      ALTER TABLE #{table}
        DROP CONSTRAINT #{name},
        ADD CONSTRAINT #{name} FOREIGN KEY (#{column}) REFERENCES #{ref}(id)
          ON DELETE #{rule} NOT VALID
      """
    end

    for {table, name, _column, _ref} <- @keys do
      execute "ALTER TABLE #{table} VALIDATE CONSTRAINT #{name}"
    end
  end
end
