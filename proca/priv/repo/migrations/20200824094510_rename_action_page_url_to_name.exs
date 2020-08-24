defmodule Proca.Repo.Migrations.RenameActionPageUrlToName do
  use Ecto.Migration

  def change do
    rename table(:action_pages), :url, to: :name

    remove_schema = """
    UPDATE action_pages
    SET name = REPLACE(REPLACE(name, 'http://', ''), 'https://', '')
    """

    add_schema = """
    UPDATE action_pages
    SET name = 'https://' || name
    """

    execute remove_schema, add_schema
  end
end
