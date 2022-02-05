defmodule Proca.Repo.Migrations.RenameUsersPkeyConstraint do
  use Ecto.Migration

  def change do
    up = "alter table users rename constraint users_pkey1 to users_pkey"
    down = "alter table users rename constraint users_pkey to users_pkey1"
    execute up, down
  end
end
