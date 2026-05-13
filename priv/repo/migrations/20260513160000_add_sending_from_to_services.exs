defmodule Proca.Repo.Migrations.AddSendingFromToServices do
  use Ecto.Migration

  def change do
    alter table(:services) do
      add :sending_from, :string
    end
  end
end
