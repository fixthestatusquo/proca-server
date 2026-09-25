defmodule Proca.Repo.Migrations.DeliverOrphanSecondaryActions do
  use Ecto.Migration

  # Orphan secondary actions (addAction with a contact_ref that never resolved to
  # a supporter) used to be inserted as :new and then ignored forever: the
  # UnprocessedActions sweep INNER JOINs supporters, so it never saw them, and
  # the stats recalculation only counts accepted/delivered.
  #
  # New secondary actions are now written as :delivered by
  # ProcaWeb.Resolvers.Action.add_action/3; this backfills the orphan rows
  # created before that change so they are counted again.
  #
  # Raw ints because the columns are EctoEnum-backed:
  #   processing_status - new = 0, delivered = 4
  def up do
    execute("""
    UPDATE actions
    SET processing_status = 4
    WHERE (supporter_id IS NULL OR supporter_id = 0)
      AND with_consent = false
      AND processing_status = 0
    """)
  end

  # Irreversible: we cannot tell a backfilled orphan from an action that was
  # legitimately delivered, so do not reset them to :new.
  def down, do: :ok
end
