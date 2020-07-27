defmodule Proca.Source do
  use Ecto.Schema
  import Ecto.Query
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


  def normalize_tracking_codes(tracking_codes) do
    t = if Map.has_key? tracking_codes, :content do
      tracking_codes
    else
      Map.put(tracking_codes, :content, "")
    end
    t
  end

  def get_or_create_by(tracking_codes, attempt_no \\ 0) do
    t = normalize_tracking_codes(tracking_codes)
    # look it up
    case Repo.one from(s in Source, where:
          s.campaign == ^t.campaign and
          s.source == ^t.source and
          s.content == ^t.content) do
      found_source = %Source{} -> {:ok, found_source}

      # Not found, let us create it
      # In case of race condition between SELECT and INSERT,
      # we will get unique index error and retry (limit to 2 attempts)
      nil ->
          try do
            Source.build_from_attrs(t)
            |> Repo.insert
          rescue Ecto.ConstraintError ->
            if attempt_no < 2 do
              get_or_create_by(t, attempt_no + 1)
            else
              {:error, "Cannot create Source for these tracking codes"}
            end
          end
    end
  end
end
