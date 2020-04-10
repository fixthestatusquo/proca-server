defmodule Proca.Repo.Migrations.ActionPageLinkToOrg do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do

      add :org_id, references(:orgs)
    end
  end
end
