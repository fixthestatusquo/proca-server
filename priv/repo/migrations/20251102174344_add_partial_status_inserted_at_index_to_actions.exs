defmodule Proca.Repo.Migrations.AddPartialStatusInsertedAtIndexToActions do
  use Ecto.Migration

  def change do
    create_if_not_exists index(
                           :actions,
                           [:processing_status, :inserted_at],
                           where: "testing",
                           name: :actions_partial_status_inserted_at_index
                         )
  end
end
