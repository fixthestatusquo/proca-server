defmodule Proca.Repo.Migrations.AddTransactionalEmailBudgetToOrgs do
  use Ecto.Migration

  def change do
    alter table(:orgs) do
      # number of emails to send via transactional_email_backend before falling
      # back to email_backend (warming up a new backend / capping its usage).
      # nil means no limit.
      add :transactional_email_budget, :integer, null: true
    end
  end
end
