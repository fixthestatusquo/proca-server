defmodule Proca.Repo.Migrations.AddTestingFlagToAction do
  use Ecto.Migration

  def up do
    alter table(:actions) do
      add :testing, :boolean, default: false, null: false
    end

    execute """
    update actions SET processing_status = 4, testing = true WHERE processing_status = 8
    """
  end

  def down do
    execute """
    update actions SET processing_status = 8 WHERE processing_status = 4 and testing
    """

    alter table(:actions) do
      remove :testing
    end
  end
end
