defmodule Proca.Consent do
  use Ecto.Schema
  import Ecto.Changeset

  schema "consents" do
    field :communication, :boolean, default: false
    field :delivery, :boolean, default: false
    field :given_at, :utc_datetime
    field :scopes, {:array, :string}
    belongs_to :contact, Proca.Contact

    timestamps()
  end

  @doc false
  def changeset(consent, attrs) do
    consent
    |> cast(attrs, [:given_at, :communication, :delivery, :scopes])
    |> validate_required([:given_at, :communication, :delivery, :scopes])
  end

  def from_opt_in(opt_in) do
    %Proca.Consent{}
    |> cast(%{
          communication: opt_in,
          delivery: true,
          given_at: DateTime.utc_now,
          scopes: ["email"]
            }, [:communication, :delivery, :given_at, :scopes])
  end
end
