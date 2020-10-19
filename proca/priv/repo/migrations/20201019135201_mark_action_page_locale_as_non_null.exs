defmodule Proca.Repo.Migrations.MarkActionPageLocaleAsNonNull do
  use Ecto.Migration

  def change do
    alter table(:action_pages) do
      modify :locale, :string, null: false
    end
  end
end
