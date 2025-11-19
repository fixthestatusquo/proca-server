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
  import Logger

  @primary_key {:id, Ecto.UUID, autogenerate: true}

  schema "targets" do
    field :name, :string
    field :external_id, :string
    field :area, :string
    field :locale, :string
    field :fields, :map, default: %{}

    belongs_to :campaign, Proca.Campaign
    has_many :emails, Proca.TargetEmail, on_replace: :delete
    has_many :messages, Proca.Action.Message

    timestamps()
  end

  @doc false
  def changeset(target, attrs) do
    target
    |> cast(attrs, [:name, :locale, :campaign_id, :fields, :area, :external_id])
    |> validate_required([:name, :external_id])
    |> validate_flat_map(:fields)
    |> unique_constraint(:external_id)
    |> validate_format(:locale, ~r/^[a-z]{2}(_[A-Z]{2})?$/)
    |> check_constraint(:fields, name: :max_fields_size)
  end

  def deleteset(target) do
    target
    |> change()
    |> foreign_key_constraint(
      :messages,
      name: :messages_target_id_fkey,
      message: "has messages"
    )
  end

  def all(query, [{:external_id, external_id} | kw]) do
    import Ecto.Query, only: [where: 3]

    query
    |> where([t], t.external_id == ^external_id)
    |> all(kw)
  end

  def all(query, [{:external_ids, external_ids} | kw]) do
    import Ecto.Query, only: [where: 3]

    query
    |> where([t], t.external_id in ^external_ids)
    |> all(kw)
  end

  def all(query, [{:name, name} | kw]) do
    import Ecto.Query

    query
    |> where([t], t.name == ^name)
    |> all(kw)
  end

  def all(query, [{:campaign, c} | kw]) do
    import Ecto.Query

    query
    |> where([t], t.campaign_id == ^c.id)
    |> all(kw)
  end

  def upsert(input, records_by_external_id \\ nil)

  def upsert(input, nil) when is_map(input) do
    record = one(external_id: input.external_id, preload: [:emails, :campaign])
    upsert_one(input, %{input.external_id => record})
  end

  def upsert(input, nil) when is_list(input) do
    ids = get_in(input, [Access.all(), :external_id])
    records = all(external_ids: ids, preload: [:emails, :campaign])

    records_map =
      for rec <- records, into: %{} do
        {rec.external_id, rec}
      end

    Enum.map(input, &upsert_one(&1, records_map))
  end

  def upsert_one(input, records_by_external_id) do
    record = records_by_external_id[input[:external_id]] || %Target{emails: [], campaign: nil}

    change = Target.changeset(record, input)

    case input[:emails] do
      nil ->
        change

      emails ->
        emails =
          for input <- emails do
            case Enum.find(record.emails, fn %{email: e} -> e == input.email end) do
              %TargetEmail{} = te -> TargetEmail.changeset(te, input)
              nil -> TargetEmail.changeset(%TargetEmail{}, input)
            end
          end

        put_assoc(change, :emails, emails)
    end
  end

  def handle_bounce(%{id: id, email: email, reason: reason} = params) do
    case TargetEmail.one(message_id: id, email: email) do
      # ignore a bounce when not found
      nil ->
        warn("Could not find target email #{email} for message id #{id}")
        {:ok, %TargetEmail{}}

      target_email ->
        Repo.update!(change(target_email, email_status: reason, error: params[:error]))
    end
  end
end
