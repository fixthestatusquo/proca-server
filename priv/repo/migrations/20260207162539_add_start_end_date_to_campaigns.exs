defmodule Proca.Repo.Migrations.AddStartEndDateToCampaigns do
  use Ecto.Migration

  def up do
    alter table(:campaigns) do
      add :start_date, :date
      add :end_date, :date
    end

    create_if_not_exists index(:campaigns, [:start_date])
    create_if_not_exists index(:campaigns, [:end_date])
  end

  def down do
    drop_if_exists index(:campaigns, [:start_date])
    drop_if_exists index(:campaigns, [:end_date])

    alter table(:campaigns) do
      remove :start_date
      remove :end_date
    end
  end
end
