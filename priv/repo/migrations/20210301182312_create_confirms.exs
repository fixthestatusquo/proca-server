defmodule Proca.Repo.Migrations.CreateConfirms do
  use Ecto.Migration

  def change do
    create table(:confirms) do
      add :operation, ConfirmOperation.type(), null: false
      add :subject_id, :integer, null: false
      add :object_id, :integer, null: true
      add :email, :string, null: true
      add :code, :string, null: false
      add :charges, :integer, null: false

      timestamps()
    end

    create unique_index(:confirms, [:code])
  end
end
