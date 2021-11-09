defmodule Proca.Repo.Migrations.MoveInstancePermissionsToUsersTable do
  use Ecto.Migration

  def up do
    alter table(:users) do 
      add :perms, :integer, null: false, default: 0
    end 

    execute """
      update users
      SET perms = i_perms
      FROM (SELECT user_id, bit_or(perms & x'0F'::int) as i_perms FROM staffers GROUP BY 1) st 
      WHERE users.id = st.user_id
    """

    execute """
      update staffers
      SET perms = staffers.perms & x'FFF0'::int
    """
  end

  def down do 
    execute """
      update staffers
      SET perms = staffers.perms | users.perms
      FROM users WHERE users.id = staffers.user_id ;
    """

    alter table(:users) do 
      remove :perms
    end

  end
end
