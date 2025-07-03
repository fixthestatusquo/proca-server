defmodule Proca.Repo.Migrations.RemoveConfirmProcessingFormOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      remove :confirm_processing
    end
  end
end
