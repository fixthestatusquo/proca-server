defmodule Proca.Repo.Migrations.AddTemplateToMttAndNameToMessage do
  use Ecto.Migration

  def change do
    alter table(:mtt) do
      add :message_template, :string, null: true
      add :digest_template, :string, null: true
    end

    alter table(:messages) do
      add :email_from, :string, null: false, default: ""
    end
  end
end
