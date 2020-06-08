defmodule Proca.Repo.Migrations.CreateProcessingFlags do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :processing_status, ProcessingStatus.type(), default: 0, null: false
    end

    alter table(:actions) do
      add :processing_status, ProcessingStatus.type(), default: 0, null: false
    end
  end
end
