defmodule Proca.Repo.Migrations.AddSignKeyToContacts do
  use Ecto.Migration

  def change do
    alter table(:contacts) do
      add :sign_key_id, references(:public_keys, on_delete: :nothing), null: true
    end

    org_name = Application.get_env(:proca, Proca)[:org_name]
    execute """
    UPDATE contacts
    SET sign_key_id = (SELECT pk.id FROM public_keys pk JOIN orgs o ON pk.org_id = o.id
                      WHERE pk.expired_at is null and o.name = '#{org_name}')
    WHERE crypto_nonce is not null
    """
  end
end
