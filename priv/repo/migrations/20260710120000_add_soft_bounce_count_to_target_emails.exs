defmodule Proca.Repo.Migrations.AddSoftBounceCountToTargetEmails do
  use Ecto.Migration

  def change do
    alter table(:target_emails) do
      add :soft_bounce_count, :integer, default: 0, null: false
    end
  end
end
