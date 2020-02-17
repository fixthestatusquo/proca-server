defmodule Proca.Repo.Migrations.CreateOrgs do
  use Ecto.Migration

  def change do
    create table(:orgs) do
      add :name, :string, null: false
      add :title, :string, null: false

      timestamps()
    end

  end
end
