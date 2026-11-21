defmodule Proca.Repo.Migrations.CreateTransactionalEmails do
  use Ecto.Migration

  # Issue #477, step 1: the table only. Nothing reads it yet and no data is
  # copied from the old *_template / supporter_confirm columns here.
  #
  # One row = settings for one role at one scope:
  #   org scope         campaign_id NULL,     action_page_id NULL
  #   campaign scope    campaign_id set,      action_page_id NULL
  #   action_page scope campaign_id NULL,     action_page_id set
  # org_id is always the org owning the scope (campaign.org_id / action_page.org_id).
  #
  # state / mechanism / template_ref / config: NULL = inherit from the parent scope.
  def change do
    create table(:transactional_emails) do
      add :org_id, references(:orgs, on_delete: :delete_all), null: false
      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: true
      add :action_page_id, references(:action_pages, on_delete: :delete_all), null: true

      add :role, :string, null: false
      add :state, :string, null: true
      add :mechanism, :string, null: true
      add :template_ref, :string, null: true
      add :config, :map, null: true

      timestamps()
    end

    create constraint(:transactional_emails, :one_scope,
             check: "campaign_id IS NULL OR action_page_id IS NULL"
           )

    # One row per role and scope. NULLS NOT DISTINCT (Postgres 15+) makes the
    # NULL campaign_id / action_page_id of org rows count as equal.
    # ecto_sql 3.7 has no option for it, hence plain SQL.
    execute(
      """
      CREATE UNIQUE INDEX transactional_emails_role_scope_index
        ON transactional_emails (role, org_id, campaign_id, action_page_id)
        NULLS NOT DISTINCT
      """,
      "DROP INDEX transactional_emails_role_scope_index"
    )
  end
end
