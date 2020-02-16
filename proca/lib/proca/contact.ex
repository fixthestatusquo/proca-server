defmodule Proca.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :address, :string
    field :email, :string
    field :encrypted, :string
    field :first_name, :string
    field :name, :string
    field :phone, :string
    field :public_key_id, :id

    many_to_many(
      :signatures,
      Signature,
      join_through: "contact_signatures",
      on_replace: :delete
    )

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :first_name, :email, :phone, :address, :encrypted])
    |> validate_required([:name, :first_name, :email, :phone, :address, :encrypted])
  end
end
