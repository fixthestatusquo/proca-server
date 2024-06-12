defmodule Proca.Repo.Migrations.AddOrgReplyEnabled do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :reply_enabled, :boolean, default: true
    end
  end
end
