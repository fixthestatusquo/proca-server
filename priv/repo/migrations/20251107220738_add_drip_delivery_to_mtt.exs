defmodule Proca.Repo.Migrations.AddDripDeliveryToMtt do
  use Ecto.Migration

  def change do
    alter table(:mtt) do
      add :drip_delivery, :boolean, default: true
    end
  end
end
