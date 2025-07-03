defmodule Proca.Repo.Migrations.AddEventProcessingFlagToOrg do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :event_processing, :boolean, null: false, default: false
      add :confirm_processing, :boolean, null: false, default: false
    end
  end
end
