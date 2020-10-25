defmodule Proca.Repo.Migrations.ChangeNamesToCitext do
  use Ecto.Migration

  def up do
    alter table(:orgs) do
      modify :name, :citext, null: false
    end

    alter table(:campaigns) do
      modify :name, :citext, null: false
    end

    alter table(:action_pages) do
      modify :name, :citext, null: false
    end

  end

  def down do
    alter table(:orgs) do
      modify :name, :text, null: false
    end

    alter table(:campaigns) do
      modify :name, :text, null: false
    end

    alter table(:action_pages) do
      modify :name, :text, null: false
    end
  end
end
