defmodule Proca.TargetEmail do
  @moduledoc """
  TargetEmail contains the email data for a Target
  """

  use Ecto.Schema
  import Ecto.Changeset

  schema "target_emails" do
    field :email, :string
    field :email_status, EmailStatus, default: :none
    belongs_to :target, Proca.Target, type: Ecto.UUID

    timestamps()
  end

  @doc false
  def changeset(target_email, attrs) do
    target_email
    |> cast(attrs, [:email, :target_id])
    |> validate_required([:email, :target_id])
  end
end
