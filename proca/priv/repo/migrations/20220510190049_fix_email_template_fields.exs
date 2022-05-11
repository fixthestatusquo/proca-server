defmodule Proca.Repo.Migrations.FixEmailTemplateFields do
  use Ecto.Migration

  def change do
    alter table(:email_templates) do
      modify :html, :text, null: false
      modify :text, :text, null: true
    end
  end
end
