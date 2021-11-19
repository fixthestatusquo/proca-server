defmodule Proca.Target do
  @moduledoc """
  Target represents a target of a campaign, and contains information about the Target
  """

  use Ecto.Schema
  alias Proca.{Repo, Target, TargetEmail}
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "targets" do
    field :name, :string
    field :external_id, :string
    field :area, :string
    field :fields, :map, default: %{}

    belongs_to :campaign, Proca.Campaign
    has_many :emails, Proca.TargetEmail, on_delete: :delete_all, on_replace: :delete

    timestamps()
  end

  @doc false
  def changeset(target, attrs) do
    target
    |> cast(attrs, [:name, :campaign_id, :fields, :area, :external_id])
    |> validate_required([:name, :external_id])
    |> unique_constraint(:external_id)
  end

  def upsert(target, emails) do
    (get(external_id: target.external_id) || %Target{})
    |> Target.changeset(target)
    |> put_assoc(:emails, emails)
  end

  def get(queryable, [external_id: external_id]) do
    from(t in queryable, where: t.external_id == ^external_id)
    |> preloads()
    |> Repo.one()
  end

  def preloads(queryable) do
    queryable |> preload([t], [:emails, :campaign])
  end

  def get(target), do: get(Target, target)

  def handle_bounce(args) do
    target_email = get_target_email(args.id, args.email)
    target_email = change(target_email, email_status: args.reason)
    Repo.update!(target_email)
  end

  def get_target_email(id, email) do
    query = from(
      te in TargetEmail,
      join: t in Target,
      on: t.id == te.target_id,
      where: te.email == ^email and t.id == ^id,
      limit: 1
    )

    Repo.one(query)
  end
end
