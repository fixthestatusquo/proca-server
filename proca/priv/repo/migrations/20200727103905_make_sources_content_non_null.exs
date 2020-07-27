defmodule Proca.Repo.Migrations.MakeSourcesContentNonNull do
  use Ecto.Migration

  def change do
    # We need to fix the duplicated sources, lets create temporary table with
    # just first occurance of code combination
    execute """
    CREATE TEMPORARY TABLE s (id integer, source text, medium text, campaign text);
    """
    execute """
    INSERT INTO s
    SELECT distinct ON (source, medium, campaign) id, source, medium, campaign
    FROM sources
    """

    # Lets update supporters and actions to point to this first source record
    execute """
    update supporters
    set source_id = s.id
    from sources, s
    where sources.id = supporters.source_id AND sources.source = s.source and sources.medium = s.medium and sources.campaign = s.campaign;
    """
    execute """
    update actions
    set source_id = s.id
    from sources, s
    where sources.id = actions.source_id AND sources.source = s.source and sources.medium = s.medium and sources.campaign = s.campaign;
    """

    # Remove the extra rows
    execute """
    delete from sources where id not in (select id from s);
    """

    # set the content = NULL -> ""
    execute """
    update sources SET content = '' where content is null
    """

    # Do not let content be null
    alter table(:sources) do
      modify :content, :string, null: :false
    end
  end
end
