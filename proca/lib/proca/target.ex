defmodule Proca.Target do
  @moduledoc """
  Target represents a target of a campaign, and contains information about the Target
  """

  use Ecto.Schema
  use Proca.Schema, module: __MODULE__
  alias Proca.{Repo, Target, TargetEmail}
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

  def all(query, [{:external_id, external_id} | kw]) do
    import Ecto.Query, only: [where: 3]
    query
    |> where([t], t.external_id == ^external_id)
    |> all(kw)
  end

  def upsert(target, emails) do
    (one(external_id: target.external_id, preload: [:emails, :campaign]) || %Target{})
    |> Target.changeset(target)
    |> put_assoc(:emails, emails)
  end

  def handle_bounce(args) do
    case get_target_email(args.id, args.email) do
      nil -> {:ok, %TargetEmail{}}  # ignore a bounce when not found
      target_email ->
        Repo.update! change(target_email, email_status: args.reason)
    end
  end

  def get_target_email(id, email) do
    TargetEmail.one(target_id: id, email: email)
  end
end
