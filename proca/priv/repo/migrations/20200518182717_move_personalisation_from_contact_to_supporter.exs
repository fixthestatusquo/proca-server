defmodule Proca.Repo.Migrations.MovePersonalisationFromContactToSupporter do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :first_name, :string
      add :email, :string
    end

    copy_from_contacs = """
    UPDATE supporters
    SET first_name = contacts.first_name, email = contacts.email
    FROM contacts
    WHERE supporters.id = contacts.supporter_id
    """

    copy_to_contacs = """
    UPDATE contacts
    SET first_name = supporters.first_name, email = supporters.email
    FROM supporters
    WHERE supporters.id = contacts.supporter_id
    """

    alter table(:contacts) do
      remove :address
      remove :email
      remove :phone
      remove :first_name
      remove :name
    end
    

  end
end
