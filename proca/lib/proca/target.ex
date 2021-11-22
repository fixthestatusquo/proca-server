defmodule Proca.Target do
  @moduledoc """
  Target represents a target of a campaign, and contains information about the Target
  """

  use Ecto.Schema
  alias Proca.{Repo, Target}
  import Ecto.Changeset
  import Ecto.Query
  import Proca.Validations, only: [validate_flat_map: 2]

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
    |> validate_flat_map(:fields)
    |> unique_constraint(:external_id)
    |> check_constraint(:fields, name: :max_fields_size)
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
end
