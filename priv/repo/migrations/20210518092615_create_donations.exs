defmodule Proca.Repo.Migrations.CreateDonation do
  use Ecto.Migration

  def change do
    create table(:donations) do
      add :schema, DonationSchema.type(), default: nil, null: true
      add :payload, :map, null: false
      add :amount, :decimal, null: false
      add :currency, :text, null: false
      add :action_id, references(:actions, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:donations, [:action_id])
  end
end
