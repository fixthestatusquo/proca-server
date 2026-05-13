defmodule Proca.Repo.Migrations.AddSenderRewriteToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :sender_rewrite, :boolean, default: true
    end
  end
end
