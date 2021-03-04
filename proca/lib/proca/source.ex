defmodule Proca.Source do
  @moduledoc """
  Holds utm codes. Will be reused by many actions
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Proca.Changeset
  alias Proca.Repo
  alias Proca.Source

  schema "sources" do
    field :campaign, :string
    field :content, :string, default: ""
    field :medium, :string
    field :source, :string
    field :location, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:source, :medium, :campaign, :content, :location])
    |> validate_required([:source, :medium, :campaign, :content, :location])
  end

  def build_from_attrs(attrs) do
    %Source{}
    |> cast(attrs, [:source, :medium, :campaign, :content, :location])
    |> validate_required([:source, :medium, :campaign])
    |> trim(:source, 255)
    |> trim(:medium, 255)
    |> trim(:campaign, 255)
    |> trim(:content, 255)
    |> trim(:location, 255)
  end

  def get_or_create_by(tracking_codes) do
    build_from_attrs(tracking_codes)
    |> Repo.insert([
      on_conflict: [set: [updated_at: DateTime.utc_now]],
      conflict_target: [:source, :medium, :campaign, :content, :location]
    ])
  end
end
