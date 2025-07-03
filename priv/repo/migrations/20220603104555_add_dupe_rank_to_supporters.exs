defmodule Proca.Repo.Migrations.AddDupeRankToSupporters do
  use Ecto.Migration

  def change do
    alter table(:supporters) do
      add :dupe_rank, :integer, null: true
    end

    execute """
            UPDATE supporters
            SET dupe_rank = r.rank -1
            FROM
            (
              SELECT
                s.id,
                rank() over (partition by s.campaign_id, s.fingerprint order by s.inserted_at)
              FROM supporters s
            ) r
            WHERE
            supporters.id = r.id
            """,
            ""
  end
end
