defmodule Proca.Repo.Migrations.AddConfigToOrgAndCampaign do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :config, :map, null: :false, default: "{}"
    end

    alter table(:campaigns) do
      add :config, :map, null: :false, default: "{}"
    end
  end
end
