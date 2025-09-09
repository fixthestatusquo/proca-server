defmodule Proca.Repo.Migrations.AddMaxMessagesPerHourAndTimezoneToMtt do
  use Ecto.Migration

  def change do
    alter table(:mtt) do
      add :max_messages_per_hour, :integer, null: true
      add :timezone, :string, null: true
    end
  end
end
