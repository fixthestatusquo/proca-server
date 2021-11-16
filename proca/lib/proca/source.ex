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
    field :campaign, :string, default: "unknown"
    field :content, :string, default: ""
    field :medium, :string, default: "unknown"
    field :source, :string, default: "unknown"
    field :location, :string, default: ""

    timestamps()
  end

  @doc false
  def changeset(source, attrs) do
    source
    |> cast(attrs, [:source, :medium, :campaign, :content, :location])
    |> validate_required([:source, :medium, :campaign])
  end

  def build_from_attrs(attrs) do
    attrs = attrs
    |> default_location()

    %Source{}
    |> cast(attrs, [:source, :medium, :campaign, :content, :location])
    |> validate_required([:source, :medium, :campaign])
    |> trim(:source, 255)
    |> trim(:medium, 255)
    |> trim(:campaign, 255)
    |> trim(:content, 255)
    |> trim(:location, 255)
  end

  def default_location(attrs = %{location: nil}), do: Map.put(attrs, :location, "")
  def default_location(attrs), do: attrs

  def get_or_create_by(tracking_codes) do
    build_from_attrs(tracking_codes)
    |> Repo.insert([
      on_conflict: [set: [updated_at: DateTime.utc_now]],
      conflict_target: [:source, :medium, :campaign, :content, :location]
    ])
  end

  def well_formed_url?(%URI{host: h, path: p, scheme: s})
  when h != nil and h != "" and p != nil and s in ["https", "http", "ws", "wss"], do: true
  def well_formed_url?(_), do: false

  def strip_url(%URI{host: h, path: p, scheme: s, port: prt}) do 
    %URI{
      host: h,
      path: p,
      scheme: s,
      port: prt
    }
    |> URI.to_string()
  end

  @doc """
  Get location from http referer header and location explicitly sent by user.
  As this is possible to get
  """
  def get_tracking_location(location, referer) when is_bitstring(location) and is_bitstring(referer) do 
    loc_uri = URI.parse(location)
    ref_uri = URI.parse(referer)
    referer = strip_url ref_uri

    if well_formed_url? ref_uri do 
      if well_formed_url? loc_uri do 
        if String.starts_with?(location, referer) do 
          strip_url loc_uri
        else
          Sentry.capture_message("Tracking location '#{location}' does not start with '#{referer}'", result: :none)
          # the location provided is outside of the referer scope. Use referer
          strip_url ref_uri
        end
      else 
        strip_url ref_uri
      end
    else
      nil
    end
  end

  def get_tracking_location(nil, referer) when is_bitstring(referer) do 
    ref_uri = URI.parse(referer)
    if well_formed_url? ref_uri do  
      referer 
    else 
      nil
    end
  end

  def get_tracking_location(_, _), do: nil
end
