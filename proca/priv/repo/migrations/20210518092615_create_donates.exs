defmodule Proca.Repo.Migrations.CreateDonates do
  use Ecto.Migration

  def change do
    create table(:donates) do
      add :schema, DonateSchema.type(), default: nil, null: true
      add :payload, :map, null: false
      add :amount, :decimal, null: false
      add :currency, :text, null: false
      add :action_id, references(:actions, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:donates, [:action_id])
  end
end
