defmodule Proca.Repo.Migrations.AddSizeLimitToActionFields do
  use Ecto.Migration

  def change do
    create constraint(:actions, :max_fields_size, check: "pg_column_size(fields) <= 5120")
  end
end
