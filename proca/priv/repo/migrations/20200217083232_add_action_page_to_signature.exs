defmodule Proca.Repo.Migrations.AddActionPageToSignature do
  use Ecto.Migration

  def change do
    alter table(:signatures) do
      add :action_page_id, references(:action_pages, on_delete: :nilify_all), null: false
    end
  end
end
