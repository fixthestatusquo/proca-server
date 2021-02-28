defmodule Proca.Repo.Migrations.AddAreaToSupporter do
  use Ecto.Migration

  def change do
    alter table(:supporters) do 
      add :area, :string, size: 5, null: true
    end
  end
end
