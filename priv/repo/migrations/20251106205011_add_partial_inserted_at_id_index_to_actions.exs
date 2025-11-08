defmodule Proca.Repo.Migrations.AddPartialInsertedAtIdIndexToActions do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:actions,
      [:id, :inserted_at],
      where: "processing_status IN (0, 3)",
      name: :partial_inserted_at_id_index
    )
  end
end
