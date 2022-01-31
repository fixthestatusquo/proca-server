defmodule Proca.Repo.Migrations.AddTestEmailToMtt do
  use Ecto.Migration

  def change do
    alter table(:mtt) do
      add :test_email, :string, null: true
    end
  end
end
