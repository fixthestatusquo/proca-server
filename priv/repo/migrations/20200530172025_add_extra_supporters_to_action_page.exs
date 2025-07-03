defmodule Proca.Repo.Migrations.AddExtraSupportersToActionPage do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      add :extra_supporters, :integer, null: false, default: 0
    end
  end
end
