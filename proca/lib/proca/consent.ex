defmodule Proca.Consent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "consents" do
    field :communication, :boolean, default: false
    field :delivery, :boolean, default: false
    field :given_at, :naive_datetime
    field :scopes, {:array, :string}
    field :contact_id, :id

    timestamps()
  end

  @doc false
  def changeset(consent, attrs) do
    consent
    |> cast(attrs, [:given_at, :communication, :delivery, :scopes])
    |> validate_required([:given_at, :communication, :delivery, :scopes])
  end
end
