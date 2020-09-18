defmodule Proca.Repo.Migrations.AddEmailOptInToOrg do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :email_opt_in, :boolean, default: false, null: false
      add :email_opt_in_template, :string, null: true
    end
  end
end
