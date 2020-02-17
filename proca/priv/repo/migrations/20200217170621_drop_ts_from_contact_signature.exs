defmodule Proca.Repo.Migrations.DropTsFromContactSignature do
  use Ecto.Migration

  def change do
    alter table(:contact_signatures) do
      remove :inserted_at
      remove :updated_at
    end
  end
end
