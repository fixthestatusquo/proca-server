defmodule Proca.Repo.Migrations.ActionPageNullifyOrgId do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE action_pages DROP CONSTRAINT action_pages_org_id_fkey"
    alter table(:action_pages) do
      modify :org_id, references(:orgs, on_delete: :nilify_all)
    end
  end
end
