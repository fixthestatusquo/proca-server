defmodule Proca.Repo.Migrations.AddContactSchemaToCampaigns do
  use Ecto.Migration

  def up do
    alter table(:campaigns) do
      add :contact_schema, ContactSchema.type(), default: 0, null: false
    end
    execute """
      UPDATE campaigns 
      SET contact_schema = orgs.contact_schema
      FROM orgs 
      WHERE campaigns.org_id = orgs.id 
    """
  end

  def down do 
    alter table(:campaigns) do 
      remove :contact_schema
    end
  end
end
