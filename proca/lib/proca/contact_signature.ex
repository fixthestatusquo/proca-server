defmodule Proca.ContactSignature do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contact_signatures" do
    field :contact_id, :id
    field :signature_id, :id

    timestamps()
  end

  @doc false
  def changeset(contact_signature, attrs) do
    contact_signature
    |> cast(attrs, [])
    |> validate_required([])
  end
end
