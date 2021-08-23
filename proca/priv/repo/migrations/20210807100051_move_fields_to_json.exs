defmodule Proca.Repo.Migrations.MoveFieldsToJson do
  use Ecto.Migration

  def up do
    alter table(:actions) do 
      add :fields, :map, null: false, default: "{}"
    end

    move_to_json = """
    UPDATE actions 
    SET fields = f.json 
    FROM (
      SELECT action_id, jsonb_object_agg(key, value)  as json
      FROM fields 
      GROUP BY action_id
    ) f
    WHERE actions.id = f.action_id
    """
    execute move_to_json
    drop table(:fields)

    alter table(:campaigns) do
      add :transient_actions, {:array, :string}, null: false, default: []
    end
  end

  def down do 
    create table(:fields) do
      add :key, :string, null: false
      add :value, :string, null: false
      add :transient, :boolean, null: false, default: false
      add :action_id, references(:actions, on_delete: :delete_all), null: false
    end

    create index(:fields, [:key])


    move_to_fields = """
    INSERT INTO fields (key, value, action_id) 
    SELECT 
      x.key, a.fields -> x.key, a.id
    FROM 
    (SELECT 
      actions.id,
      jsonb_object_keys(actions.fields) as key
      FROM actions
    ) x
    JOIN 
    actions a ON a.id = x.id
    """

    execute move_to_fields

    alter table(:actions) do 
      remove :fields
    end

    alter table(:campaigns) do
      remove :transient_actions
    end
  end
end
