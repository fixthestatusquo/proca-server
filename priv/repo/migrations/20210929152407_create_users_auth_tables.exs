defmodule Proca.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    drop constraint(:confirms, :confirms_creator_id_fkey)
    drop constraint(:staffers, :staffers_user_id_fkey)

    drop unique_index(:users, [:email])
    rename table(:users), to: table(:pow_users)

    create table(:users) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      add :perms, :integer, null: false, default: 0
      timestamps()
    end

    create unique_index(:users, [:email])

    create table(:users_tokens) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:users_tokens, [:user_id])
    create unique_index(:users_tokens, [:context, :token])

    execute """
              INSERT INTO users (id, email, hashed_password, perms, confirmed_at, inserted_at, updated_at)
              SELECT id, email, password_hash, perms, inserted_at, inserted_at, updated_at
              FROM pow_users
            """,
            ""

    drop table(:pow_users)

    execute "ALTER TABLE users_id_seq1 rename to users_id_seq", ""

    execute "SELECT setval(pg_get_serial_sequence('users', 'id'), coalesce(MAX(id), 1)) from users",
            ""

    alter table(:confirms) do
      modify :creator_id, references(:users, on_delete: :nilify_all), null: true
    end

    alter table(:staffers) do
      modify :user_id, references(:users, on_delete: :nilify_all), null: false
    end
  end
end
