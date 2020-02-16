defmodule Proca.Repo.Migrations.CreateContacts do
  use Ecto.Migration

  def change do
    create table(:contacts) do
      add :name, :string
      add :first_name, :string
      add :email, :string
      add :phone, :string
      add :address, :string
      add :encrypted, :string
      add :public_key_id, references(:public_keys, on_delete: :nothing)


      timestamps()
    end

  end
end
