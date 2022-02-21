defmodule Proca.Repo.Migrations.AddDoiThankYouToOrg do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :doi_thank_you, :boolean, null: false, default: false
    end
  end
end
