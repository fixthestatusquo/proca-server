defmodule Proca.Repo.Migrations.CreateActions do
  use Ecto.Migration

  def change do
    create table(:actions) do
      add :ref, :bytea, null: true
      add :supporter_id, references(:supporters, on_delete: :nilify_all), null: true

      add :action_type, :string, null: :false

      add :campaign_id, references(:campaigns, on_delete: :delete_all), null: false
      add :action_page_id, references(:action_pages, on_delete: :nilify_all), null: false
      add :source_id, references(:sources, on_delete: :nilify_all), null: true

      timestamps()
    end

    create index(:actions, [:action_type])
  end
end
