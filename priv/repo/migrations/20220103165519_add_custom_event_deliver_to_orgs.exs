defmodule Proca.Repo.Migrations.AddCustomEventDeliverToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :custom_event_deliver, :boolean, default: false, null: false
    end
  end
end
