defmodule Proca.Repo.Migrations.AddMaxEmailsPerHourAndTimezoneToMtt do
  use Ecto.Migration

  def change do
    alter table(:mtt) do
      add :max_emails_per_hour, :integer, null: true
      add :timezone, :string, null: false, default: "Etc/UTC"
    end
  end
end
