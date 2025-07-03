defmodule Proca.Repo.Migrations.MoveActionPageJourneyToConfig do
  use Ecto.Migration

  def up do
    execute """
      update action_pages
      SET config = jsonb_set(config, '{journey}'::text[], to_jsonb(journey), TRUE)
      WHERE journey != '{}';
    """

    alter table(:action_pages) do
      remove :journey
    end
  end

  def down do
    alter table(:action_pages) do
      add :journey, {:array, :string}, null: false, default: []
    end

    execute """
    update action_pages
    SET journey = (SELECT array_agg(step) FROM
      (SELECT jsonb_array_elements_text((a2.config->>'journey')::jsonb) as step 
       FROM action_pages a2 
       WHERE a2.id = action_pages.id ) s)
    WHERE config->>'journey' is not null
    """
  end
end
