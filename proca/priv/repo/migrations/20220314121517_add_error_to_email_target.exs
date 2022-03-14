defmodule Proca.Repo.Migrations.AddErrorToEmailTarget do
  use Ecto.Migration

  def change do
    alter table(:target_emails) do
      add :error, :string
    end
  end
end
