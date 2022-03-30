defmodule Proca.Repo.Migrations.AddIndexesToActionContacts do
  use Ecto.Migration

  def change do
    create index(:actions, [:campaign_id])
    create index(:contacts, [:org_id])
  end
end
