defmodule Proca.Repo.Migrations.AddCreatorToConfirm do
  use Ecto.Migration

  def change do
    alter table(:confirms) do
      add :creator_id, references(:staffers, on_delete: :nilify_all), null: true
    end
  end
end
