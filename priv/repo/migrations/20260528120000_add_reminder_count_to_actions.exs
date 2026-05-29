defmodule Proca.Repo.Migrations.AddReminderCountToActions do
  use Ecto.Migration

  def change do
    alter table(:actions) do
      add :reminder_count, :integer, null: false, default: 0
    end
  end
end
