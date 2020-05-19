defmodule Proca.Repo.Migrations.CreateStaffers do
  use Ecto.Migration

  def change do
    create table(:staffers) do
      add :perms, :integer, default: 0, null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    # XXX these are added automatically
    # create index(:staffers, [:org_id])
    # create index(:staffers, [:user_id])
    create unique_index(:staffers, [:org_id, :user_id])
  end
end
