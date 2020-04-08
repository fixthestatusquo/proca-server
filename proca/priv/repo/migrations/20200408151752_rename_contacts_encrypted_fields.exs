defmodule Proca.Repo.Migrations.RenameContactsEncryptedFields do
  use Ecto.Migration

  def change do
    rename table("contacts"), :encrypted, to: :payload
    rename table("contacts"), :encrypted_nonce, to: :crypto_nonce
  end
end
