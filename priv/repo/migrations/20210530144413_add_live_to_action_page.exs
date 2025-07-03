defmodule Proca.Repo.Migrations.AddLiveToActionPage do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      add :live, :boolean, default: false, null: false
    end

    execute "UPDATE action_pages set live = true", ""
  end
end
