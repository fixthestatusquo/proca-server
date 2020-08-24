defmodule Proca.Repo.Migrations.AddUniqueIndexToActionPageName do
  use Ecto.Migration

  def change do
    create unique_index(:action_pages, [:name])

  end
end
