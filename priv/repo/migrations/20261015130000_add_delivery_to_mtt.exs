defmodule Proca.Repo.Migrations.AddDeliveryToMtt do
  use Ecto.Migration

  # Phase 1 of replacing drip_delivery: add delivery next to it and fill it.
  # Plain SQL on purpose - drip_delivery will be dropped later and the
  # Proca.MTT schema will not know it anymore.
  def up do
    alter table(:mtt) do
      add :delivery, :string, null: false, default: "throttle"
    end

    execute "UPDATE mtt SET delivery = CASE WHEN drip_delivery THEN 'pacing' ELSE 'throttle' END"
  end

  def down do
    alter table(:mtt) do
      remove :delivery
    end
  end
end
