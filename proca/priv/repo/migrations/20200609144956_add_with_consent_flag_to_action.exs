defmodule Proca.Repo.Migrations.AddWithConsentFlagToAction do
  use Ecto.Migration

  def change do
    alter table(:actions) do
      add :with_consent, :boolean, default: false, null: false
    end
  end
end
