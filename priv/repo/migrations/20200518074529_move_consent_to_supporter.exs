defmodule Proca.Repo.Migrations.MoveConsentToSupporter do
  use Ecto.Migration

  def change do
    alter table(:consents) do
      add :supporter_id, :integer, null: true
    end

    supporter_id_to_consents = """
    UPDATE consents
    SET supporter_id = supporters.id
    FROM contacts, supporters
    WHERE consents.contact_id = contacts.id AND contacts.supporter_id = supporters.id
    """

    contact_id_to_consents = """
    UPDATE consents
    SET contact_id = contacts.id
    FROM contacts, supporters
    WHERE consents.supporter_id = supporters.id AND supporters.id = contacts.supporter_id
    """

    execute(supporter_id_to_consents, contact_id_to_consents)

    alter table(:consents) do
      remove :contact_id
      modify :supporter_id, references(:supporters, on_delete: :delete_all), null: false
    end
  end
end
