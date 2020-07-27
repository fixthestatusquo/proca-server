defmodule Proca.Repo.Migrations.MergeConsentsToContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :communication_consent, :boolean, default: false, null: false
      add :communication_scopes, {:array, :string}
      add :delivery_consent, :boolean, default: false, null: false
    end

    merge_sql = """
    UPDATE contacts
    SET
    communication_consent = consents.communication,
    communication_scopes = consents.scopes,
    delivery_consent = consents.delivery
    FROM
    consents
    WHERE
    contacts.supporter_id = consents.supporter_id
    """

    recreate_consents_sql = """
    INSERT INTO consents
    VALUES (supporter_id, communication, delivery, scopes, given_at)
    (SELECT
      supporter_id, communication_consent, delivery_consent, communication_scopes, inserted_at
     FROM contacts
    )
    """

    execute merge_sql, recreate_consents_sql

    drop table(:consents)

  end
end
