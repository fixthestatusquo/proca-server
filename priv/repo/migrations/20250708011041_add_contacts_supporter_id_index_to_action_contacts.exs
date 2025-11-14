defmodule Proca.Repo.Migrations.AddContactsSupporterIdIndexToActionContacts do
  use Ecto.Migration

  def change do
    create_if_not_exists index(:contacts, [:supporter_id], name: :contacts_supporter_id_index)
  end
end
