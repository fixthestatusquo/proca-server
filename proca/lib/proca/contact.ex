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
      Proca.Signature,
      join_through: "contact_signatures",
      on_replace: :delete
    )

    timestamps()
  end

  @email_format ~r{^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$}

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:name, :first_name, :email, :phone, :address, :encrypted])
    |> validate_required([:name, :first_name, :email, :phone, :address, :encrypted])
  end

  def from_sig_data(sig_data) do
    sig_data2 = Map.put(sig_data, :first_name, guess_first_name(sig_data[:name]))
    %Proca.Contact{}
    |> cast(sig_data2, [:name, :first_name, :email, :phone])
    |> validate_required([:name])
    |> validate_format(:email, @email_format)
    |> validate_format(:phone, ~r{[0-9+ -]+})

  end

  def guess_first_name(name) do
    String.split(name, ~r{[\s]+}) |> hd
  end
end
