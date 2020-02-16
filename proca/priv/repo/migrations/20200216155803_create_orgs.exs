defmodule Proca.Repo.Migrations.CreateOrgs do
  use Ecto.Migration

  def change do
    create table(:orgs) do
      add :name, :string
      add :title, :string

      timestamps()
    end

  end
end
