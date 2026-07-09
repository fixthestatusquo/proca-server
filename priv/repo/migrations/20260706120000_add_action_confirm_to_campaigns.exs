defmodule Proca.Repo.Migrations.AddActionConfirmToCampaigns do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      # Tri-state override of org.custom_action_confirm for this one campaign:
      # nil -> inherit org setting, true -> force on, false -> force off.
      add :action_confirm, :boolean, null: true
    end
  end
end
