defmodule Proca.Repo.Migrations.AddReminderFieldsToSupporters do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :reminder_count, :integer, default: 0, null: false
      add :reminder_sent_at, :utc_datetime
    end
  end
end
