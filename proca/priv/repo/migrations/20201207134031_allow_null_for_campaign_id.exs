defmodule Proca.Repo.Migrations.AllowNullForCampaignId do
  use Ecto.Migration

  def up do
    drop_constraints = """
    ALTER TABLE actions DROP CONSTRAINT IF EXISTS "actions_action_page_id_fkey";
    ALTER TABLE actions DROP CONSTRAINT IF EXISTS actions_campaign_id_fkey;
    ALTER TABLE supporters DROP CONSTRAINT IF EXISTS signatures_action_page_id_fkey;
    ALTER TABLE supporters DROP CONSTRAINT IF EXISTS signatures_campaign_id_fkey;
    ALTER TABLE supporters DROP CONSTRAINT IF EXISTS supporters_action_page_id_fkey;
    ALTER TABLE supporters DROP CONSTRAINT IF EXISTS supporters_campaign_id_fkey;
    ALTER TABLE action_pages DROP CONSTRAINT IF EXISTS "action_pages_campaign_id_fkey";
    """

    String.split(drop_constraints, "\n") |> Enum.each(fn sql ->
      if String.length(sql) > 0 do
        execute sql, ""
      end
    end)

    alter table(:actions) do
      modify :campaign_id, references(:campaigns, on_delete: :nilify_all), null: true
      modify :action_page_id, references(:action_pages, on_delete: :restrict), null: false
    end

    alter table(:supporters) do
      modify :campaign_id, references(:campaigns, on_delete: :nilify_all), null: true
      modify :action_page_id, references(:action_pages, on_delete: :restrict), null: false
    end

    alter table(:action_pages) do
      modify :campaign_id, references(:campaigns, on_delete: :nilify_all), null: true
    end
  end

  def down do
    # not setting stricter not null requirements, just let the migration rollback to run it again
  end
end
