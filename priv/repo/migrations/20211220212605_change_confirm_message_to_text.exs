defmodule Proca.Repo.Migrations.ChangeConfirmMessageToText do
  use Ecto.Migration

  def up do
    alter table(:confirms) do
      modify :message, :text, null: true
    end
  end

  def down do
    alter table(:confirms) do
      modify :message, :string, null: true
    end
  end
end
