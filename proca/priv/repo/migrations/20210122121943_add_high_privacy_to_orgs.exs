defmodule Proca.Repo.Migrations.AddHighPrivacyToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do 
      add :high_security, :boolean, null: false, default: false
    end
  end
end
