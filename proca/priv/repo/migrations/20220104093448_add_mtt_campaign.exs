defmodule Proca.Repo.Migrations.AddMttCampaign do
  use Ecto.Migration

  def change do
    create table(:mtt) do
      add :campaign_id, references(:campaigns, on_delete: :do_nothing), null: false
      add :start_at, :utc_datetime, null: false
      add :end_at, :utc_datetime, null: false
      add :sending_rate, :integer, null: false
      add :stats, :map, null: false, default: "{}"
    end
  end
end
