defmodule Proca.Repo.Migrations.AddDupeSamePageToSupporters do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :dupe_same_page, :boolean, null: true
    end
  end
end
