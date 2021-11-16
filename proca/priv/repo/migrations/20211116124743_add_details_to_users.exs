defmodule Proca.Repo.Migrations.AddDetailsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :picture_url, :text
      add :job_title, :text
      add :phone, :text
    end
  end
end
