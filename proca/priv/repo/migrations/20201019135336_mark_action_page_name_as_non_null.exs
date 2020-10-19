defmodule Proca.Repo.Migrations.MarkActionPageNameAsNonNull do
  use Ecto.Migration

  def change do
      alter table(:action_pages) do
        modify :name, :string, null: false
      end
  end
end
