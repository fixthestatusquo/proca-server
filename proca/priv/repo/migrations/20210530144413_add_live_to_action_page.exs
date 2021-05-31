defmodule Proca.Repo.Migrations.AddLiveToActionPage do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do 
      add :live, :boolean, default: false, null: false
    end
  end
end
