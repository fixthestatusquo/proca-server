defmodule Proca.Repo.Migrations.AddMessageToConfirm do
  use Ecto.Migration

  def change do
    alter table(:confirms) do 
      add :message, :string, null: true
    end
  end
end
