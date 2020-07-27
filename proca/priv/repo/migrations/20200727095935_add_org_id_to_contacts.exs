defmodule Proca.Repo.Migrations.AddOrgIdToContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :org_id, references(:orgs, on_delete: :nilify_all)
    end
  end
end
