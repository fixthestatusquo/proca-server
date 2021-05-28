defmodule Proca.Repo.Migrations.AddFrequencyUnitToDonation do
  use Ecto.Migration

  def change do
    alter table(:donations) do 
      add :frequency_unit, DonationFrequencyUnit.type(), default: 0, null: false
    end

  end
end
