defmodule Proca.Repo.Migrations.OnUserDeleteCascadeStaffers do
  use Ecto.Migration

  def up do
    execute """
    alter table staffers drop constraint staffers_user_id_fkey, add constraint staffers_user_id_fkey  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE cascade;
    """
  end
end
