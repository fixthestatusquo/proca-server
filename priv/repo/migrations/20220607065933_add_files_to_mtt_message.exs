defmodule Proca.Repo.Migrations.AddFilesToMttMessage do
  use Ecto.Migration

  def change do
    alter table(:messages) do
      add :files, {:array, :string}, null: false, default: []
    end
  end
end
