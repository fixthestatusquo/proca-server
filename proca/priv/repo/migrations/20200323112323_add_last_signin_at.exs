defmodule Proca.Repo.Migrations.AddLastSigninAt do
  use Ecto.Migration

  def change do
    alter table (:staffers) do
      add :last_signin_at, :utc_datetime, null: true
    end

  end
end
