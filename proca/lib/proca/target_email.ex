defmodule Proca.TargetEmail do
  @moduledoc """
  TargetEmail contains the email data for a Target
  """

  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  import Ecto.Changeset

  schema "target_emails" do
    field :email, :string
    field :email_status, EmailStatus, default: :none
    belongs_to :target, Proca.Target, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(target_email, attrs) do
    attrs = Proca.Contact.Input.Contact.normalize_email(attrs)

    target_email
    |> cast(attrs, [:email, :email_status, :target_id])
    |> validate_required([:email, :target_id])
  end

  def all(q, [{:email, email} | kw]) do
    import Ecto.Query

    q
    |> where([te], te.email == ^email)
    |> all(kw)
  end

  def all(q, [{:target_id, target_id} | kw]) do
    import Ecto.Query

    q
    |> where([te], te.target_id == ^target_id)
    |> all(kw)
  end

  def all(q, [{:message_id, id} | kw]) do
    import Ecto.Query

    q
    |> join(:inner, [e], t in assoc(e, :target))
    |> join(:inner, [e, t], m in assoc(t, :messages))
    |> where([e, t, m], m.id == ^id)
    |> all(kw)
  end
end
