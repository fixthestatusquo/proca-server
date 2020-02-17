defmodule Proca.Repo.Migrations.AddSourceToSignature do
  use Ecto.Migration

  def change do
    alter table (:signatures) do
      add :source_id, references(:sources, on_delete: :nilify_all), null: true
    end
  end
end
