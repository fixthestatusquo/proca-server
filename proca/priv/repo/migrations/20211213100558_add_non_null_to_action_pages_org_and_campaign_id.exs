defmodule Proca.Repo.Migrations.AddNonNullToActionPagesOrgAndCampaignId do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE action_pages DROP CONSTRAINT action_pages_org_id_fkey"
    execute "ALTER TABLE action_pages DROP CONSTRAINT action_pages_campaign_id_fkey"

    alter table(:action_pages) do
      modify :org_id, references(:orgs, on_delete: :restrict), null: false
      modify :campaign_id, references(:campaigns, on_delete: :restrict), null: false
    end
  end

  def down do
    execute "ALTER TABLE action_pages DROP CONSTRAINT action_pages_org_id_fkey"
    execute "ALTER TABLE action_pages DROP CONSTRAINT action_pages_campaign_id_fkey"

    alter table(:action_pages) do
      modify :org_id, references(:orgs, on_delete: :nilify_all), null: true
      modify :campaign_id, references(:campaigns, on_delete: :nilify_all), null: true
    end
  end
end
