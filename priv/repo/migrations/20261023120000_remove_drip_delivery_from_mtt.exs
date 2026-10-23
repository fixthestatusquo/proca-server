defmodule Proca.Repo.Migrations.RemoveDripDeliveryFromMtt do
  use Ecto.Migration

  # drip_delivery is replaced by delivery (pacing = drip, throttle = no-drip).
  # Code stopped using it in 0e689fc4; only run with that code (or newer) live.
  def up do
    alter table(:mtt) do
      remove :drip_delivery
    end
  end

  # Restore the column for older code, filled from delivery.
  def down do
    alter table(:mtt) do
      add :drip_delivery, :boolean, default: true
    end

    execute "UPDATE mtt SET drip_delivery = (delivery = 'pacing')"
  end
end
