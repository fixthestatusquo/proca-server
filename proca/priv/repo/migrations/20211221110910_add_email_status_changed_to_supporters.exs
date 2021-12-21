defmodule Proca.Repo.Migrations.AddEmailStatusChangedToSupporters do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :email_status_changed, :naive_datetime, null: true
    end
  end
end
