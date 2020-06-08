defmodule Proca.Repo.Migrations.AddThankYouTemplateRef do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      add :thank_you_template_ref, :string, null: true
    end
  end
end
