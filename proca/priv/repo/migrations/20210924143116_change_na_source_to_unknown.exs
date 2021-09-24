defmodule Proca.Repo.Migrations.ChangeNaSourceToUnknown do
  use Ecto.Migration

  def change do
    upsql = """
      UPDATE sources
      SET 
       campaign = 'unknown',
       medium = 'unknown',
       source = 'unknown'
      WHERE
       campaign = 'n/a' AND medium = 'n/a' AND source = 'n/a'
    """

    downsql = """
      UPDATE sources
      SET 
       campaign = 'n/a',
       medium = 'n/a',
       source = 'n/a'
      WHERE
       campaign = 'unknown' AND medium = 'unknown' AND source = 'unknown'
    """

    execute upsql, downsql


  end
end
