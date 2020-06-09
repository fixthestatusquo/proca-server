defmodule Proca.Repo.Migrations.AddWithConsentFlagToAction do
  use Ecto.Migration

  def change do
    alter table(:actions) do
      add :with_consent, :boolean, default: false, null: false
    end
    set_with_consent = """
    UPDATE actions
    SET with_consent = true
    FROM supporters
    WHERE supporters.id = actions.supporter_id
    AND supporters.inserted_at = actions.inserted_at
    """
    execute(set_with_consent)
  end
end
