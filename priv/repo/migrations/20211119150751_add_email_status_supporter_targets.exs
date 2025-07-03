defmodule Proca.Repo.Migrations.AddEmailStatusSupporterTargets do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :email_status, :smallint, null: false, default: 0
    end

    alter table(:target_emails) do
      add :email_status, :smallint, null: false, default: 0
    end
  end
end
