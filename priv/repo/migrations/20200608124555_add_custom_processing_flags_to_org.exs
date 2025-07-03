defmodule Proca.Repo.Migrations.AddCustomProcessingFlagsToOrg do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      add :custom_supporter_confirm, :boolean, default: false, null: false
      add :custom_action_confirm, :boolean, default: false, null: false
      add :custom_action_deliver, :boolean, default: false, null: false
      add :system_sqs_deliver, :boolean, default: false, null: false
    end
  end
end
