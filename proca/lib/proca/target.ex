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
    has_many :messages, Proca.Action.Message

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

  def all(query, [{:name, name} | kw]) do
    import Ecto.Query

    query
    |> where([t], t.name == ^name)
    |> all(kw)
  end

  def all(q, [{:campaign, c} | kw]) do
    import Ecto.Query

    q
    |> where([t], t.campaign_id == ^c.id)
    |> all(kw)
  end

  def upsert(input) do
    record =
      one(external_id: input.external_id, preload: [:emails, :campaign]) ||
        %Target{emails: [], campaign: nil}

    change = Target.changeset(record, input)

    case Map.get(input, :emails) do
      nil ->
        change

      emails ->
        emails =
          for input <- emails do
            case Enum.find(record.emails, fn %{email: e} -> e == input.email end) do
              %TargetEmail{} = te -> TargetEmail.changeset(te, input)
              nil -> struct(TargetEmail, input)
            end
          end

        put_assoc(change, :emails, emails)
    end
  end

  def handle_bounce(args) do
    case get_target_email(args.id, args.email) do
      # ignore a bounce when not found
      nil ->
        {:ok, %TargetEmail{}}

      target_email ->
        Repo.update!(change(target_email, email_status: args.reason))
    end
  end

  def get_target_email(id, email) do
    TargetEmail.one(target_id: id, email: email)
  end
end
