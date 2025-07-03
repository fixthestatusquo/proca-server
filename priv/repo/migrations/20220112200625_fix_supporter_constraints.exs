defmodule Proca.Repo.Migrations.FixSupporterConstraints do
  use Ecto.Migration

  def change do
    drop constraint(:supporters, :supporters_campaign_id_fkey)
    drop constraint(:actions, :actions_supporter_id_fkey)
    drop constraint(:contacts, :contacts_supporter_id_fkey)

    alter table(:supporters) do
      modify :campaign_id, references(:campaigns, on_delete: :restrict), null: false
    end

    alter table(:actions) do
      modify :supporter_id, references(:supporters, on_delete: :delete_all)
    end

    alter table(:contacts) do
      modify :supporter_id, references(:supporters, on_delete: :delete_all)
    end
  end
end
