defmodule Proca.Repo.Migrations.AddOrgIdToContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :org_id, references(:orgs, on_delete: :nilify_all)
    end

    execute """
    UPDATE contacts
    SET org_id = pk.org_id
    FROM public_keys pk
    WHERE contacts.public_key_id = pk.id AND contacts.org_id is null
    """

    execute """
    UPDATE contacts
    SET org_id = ap.org_id
    FROM supporters sup, action_pages ap
    WHERE sup.id = contacts.supporter_id AND ap.id = sup.action_page_id AND contacts.org_id is null
    """
  end
end
