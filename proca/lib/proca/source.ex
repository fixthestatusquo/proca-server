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

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:source, :medium, :campaign, :content])
    |> validate_required([:source, :medium, :campaign, :content])
  end

  def build_from_attrs(attrs) do
    %Proca.Source{}
    |> cast(attrs, [:source, :medium, :campaign, :content])
    |> validate_required([:source, :medium, :campaign])
    |> trim(:source, 255)
    |> trim(:medium, 255)
    |> trim(:campaign, 255)
    |> trim(:content, 255)
  end

  def normalize_tracking_codes(tracking_codes = %{content: c}) when is_bitstring(c) do
    tracking_codes
  end

  def normalize_tracking_codes(tracking_codes) do
    Map.put(tracking_codes, :content, "")
  end

  def get_or_create_by(tracking_codes) do
    t = normalize_tracking_codes(tracking_codes)
    # look it up

    %Source{
      campaign: t.campaign,
      source: t.source,
      medium: t.medium,
      content: t.content
    }
    |> Repo.insert([
      on_conflict: [set: [updated_at: DateTime.utc_now]],
      conflict_target: [:source, :medium, :campaign, :content]
    ])
  end
end
