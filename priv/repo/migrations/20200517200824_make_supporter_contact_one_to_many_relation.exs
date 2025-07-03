defmodule Proca.Repo.Migrations.MakeSupporterContactOneToManyRelation do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :supporter_id, references(:supporters, on_delete: :nilify_all), null: true
    end

    move_join_table_to_contact = """
    UPDATE contacts
    SET supporter_id = supporter_contacts.supporter_id
    FROM supporter_contacts
    WHERE  contacts.id = supporter_contacts.contact_id
    """

    recreate_join_table = """
    INSERT INTO supporter_contacts (supporter_id, contact_id)
    SELECT s.id, c.id FROM supporter s JOIN contact c ON s.id = c.supporter_id
    """

    execute(move_join_table_to_contact, recreate_join_table)
    execute "ALTER TABLE contacts DROP CONSTRAINT contacts_supporter_id_fkey"

    alter table(:contacts) do
      # set NULL to false after we filled support_id
      modify :supporter_id, references(:supporters, on_delete: :nilify_all), null: false
    end

    drop table(:supporter_contacts)
  end
end
