defmodule Proca.Repo.Migrations.AddCampaignCCSender do
  use Ecto.Migration

  def change do
    alter table(:mtt) do
      add :cc_contacts, {:array, :string}, null: false, default: []
      add :cc_sender, :boolean, default: false, null: false
    end
  end
end
