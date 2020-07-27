defmodule Proca.Repo.Migrations.AddConfigToActionPage do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      add :config, :map, null: :false, default: "{}"
      add :journey, {:array, :string}, null: :false, default: []
    end
  end
end
