defmodule Proca.Repo.Migrations.DontCascadeTargetToMessages do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE messages DROP CONSTRAINT messages_target_id_fkey"
    execute "ALTER TABLE target_emails DROP CONSTRAINT target_emails_target_id_fkey"

    alter table(:messages) do
      modify :target_id,
             references(:targets, type: :uuid, on_delete: :restrict),
             null: false
    end

    alter table(:target_emails) do
      modify :target_id,
             references(:targets, type: :uuid, on_delete: :delete_all),
             null: false
    end
  end
end
