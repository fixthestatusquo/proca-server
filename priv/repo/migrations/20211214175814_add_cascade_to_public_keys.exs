defmodule Proca.Repo.Migrations.AddCascadeToPublicKeys do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE public_keys DROP CONSTRAINT public_keys_org_id_fkey"

    alter table(:public_keys) do
      modify :org_id, references(:orgs, on_delete: :delete_all), null: false
    end
  end

  def down do
    execute "ALTER TABLE public_keys DROP CONSTRAINT public_keys_org_id_fkey"

    alter table(:public_keys) do
      modify :org_id, references(:orgs, on_delete: :nothing), null: false
    end
  end
end
