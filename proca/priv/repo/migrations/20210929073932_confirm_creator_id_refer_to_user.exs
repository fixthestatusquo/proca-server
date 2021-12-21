defmodule Proca.Repo.Migrations.ConfirmCreatorIdReferToUser do
  use Ecto.Migration

  def change do
    drop constraint(:confirms, :confirms_creator_id_fkey)

    execute """
            UPDATE confirms SET creator_id = staffers.user_id
            FROM staffers
            WHERE
            staffers.id = confirms.creator_id
            """,
            "SELECT 1"

    alter table(:confirms) do
      modify :creator_id, references(:users, on_delete: :nilify_all), null: true
    end
  end
end
