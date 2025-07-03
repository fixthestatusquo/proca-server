defmodule Proca.Repo.Migrations.AddSenderToSupporterAndFlagsToMessage do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :last_name, :string, null: true
      add :address, :string, null: true
    end

    alter table(:messages) do
      add :sent, :boolean, null: false, default: false
      add :opened, :boolean, null: false, default: false
      add :clicked, :boolean, null: false, default: false
    end
  end
end
