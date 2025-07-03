defmodule Proca.Repo.Migrations.AddSizeLimitToTargetFields do
  use Ecto.Migration

  def change do
    create constraint(:targets, :max_fields_size, check: "pg_column_size(fields) <= 5120")
  end
end
