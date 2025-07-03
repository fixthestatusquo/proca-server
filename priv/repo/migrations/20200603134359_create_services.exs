defmodule Proca.Repo.Migrations.CreateServices do
  use Ecto.Migration

  def change do
    create table(:services) do
      add :user, :string, null: false, default: ""
      add :password, :string, null: false, default: ""
      add :host, :string, null: false, default: ""
      add :path, :string, null: true
      add :name, ExternalService.type(), null: false
      add :org_id, references(:orgs, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:services, [:org_id])
  end
end
