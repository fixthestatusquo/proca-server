defmodule Proca.Repo.Migrations.AddPublicActionsToCampaign do
  use Ecto.Migration

  def change do
    alter table(:campaigns) do
      add :public_actions, {:array, :string}, null: :false, default: []
    end
  end
end
