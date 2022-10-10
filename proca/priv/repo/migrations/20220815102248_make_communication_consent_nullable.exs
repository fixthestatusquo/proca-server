defmodule Proca.Repo.Migrations.MakeCommunicationConsentNullable do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      modify :communication_consent, :boolean, default: nil, null: true
    end
  end
end
