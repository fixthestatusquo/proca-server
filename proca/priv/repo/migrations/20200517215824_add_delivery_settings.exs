defmodule Proca.Repo.Migrations.AddDeliverySettings do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      add :delivery, :boolean, null: false, default: true
    end

    alter table(:campaigns) do
      add :force_delivery, :boolean, null: false, default: false
    end

  end
end
