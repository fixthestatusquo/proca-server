defmodule Proca.ActionPage do
  @moduledoc """
  Action Page belongs to a Campaign, and represents a page (widget) where members take action.

  Action Page accepts data in many formats (See Contact.Data) and produces Contact and Supporter records.
  """
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query

  alias Proca.Repo
  alias Proca.{ActionPage, Campaign, Org, Contact, Supporter}
  alias Proca.Contact.Data

  schema "action_pages" do
    field :locale, :string
    field :name, :string
    field :delivery, :boolean
    field :journey, {:array, :string}, default: ["petition", "share"]
    field :config, :map

    belongs_to :campaign, Proca.Campaign
    belongs_to :org, Proca.Org

    field :extra_supporters, :integer, default: 0

    field :thank_you_template_ref, :string

    timestamps()
  end

  @doc false
  def changeset(action_page, attrs) do
    action_page
    |> cast(attrs, [:name, :locale, :extra_supporters, :delivery, :thank_you_template_ref, :journey])
    |> validate_required([:name, :locale])
    |> validate_format(:name, ~r/^(?:http(s)?:\/\/)?([[:alnum:]-_]+|[[:alnum:]-]+(?:\.[[:alnum:]\.-]+)+)(?:\/[[:alnum:]_-]+)+$/)
    |> remove_schema_from_name()
    |> cast_json(:config, Map.get(attrs, :config, nil))
  end

  def changeset(attrs) do
    changeset(%ActionPage{}, attrs)
  end

  # XXX move to helper
  def cast_json(changeset, _key, json_string) when is_nil(json_string) do
    changeset
  end

  def cast_json(changeset, key, json_string) do
    case Jason.decode(json_string) do
      {:ok, map} -> change(changeset, %{key => map})
      {:error, %Jason.DecodeError{data: err_data, position: err_pos, token: err_token}} ->
        add_error(changeset, key, "Cannot decode json for #{key}: #{err_data} at #{err_pos} (token: #{err_token})")
    end
  end

  @doc "Remove http or https schema from changeset name attribute, or string. (Legacy of ActionPage.url)"
  def remove_schema_from_name(changeset = %Ecto.Changeset{changes: %{name: name}}) do
    name = remove_schema_from_name(name)
    change(changeset, name: name)
  end

  def remove_schema_from_name(changeset = %Ecto.Changeset{}) do
    changeset
  end

  def remove_schema_from_name(name) when is_bitstring(name) do
    Regex.replace(~r/^https?:\/\//, name, "") 
  end

  def stringify_config(action_page = %ActionPage{}) do
    %{action_page | config: Jason.encode!(action_page.config)}
  end

  @doc """
  Upsert query of ActionPage by id or by name.

  org - what org does it belong to
  campaign - what campaign does it belong to
  attrs - attributes. The id and name will be tried in that order to lookup existing action page. If not found, it will be created.
  """
  def upsert(org, campaign, attrs = %{id: id}) do
    (Repo.get_by(ActionPage,
          org_id: org.id,
          campaign_id: campaign.id,
          id: id) || %ActionPage{})
    |> ActionPage.changeset(attrs)
    |> put_change(:campaign_id, campaign.id)
    |> put_change(:org_id, org.id)
  end

  def upsert(org, campaign, attrs = %{name: name}) do
    (Repo.get_by(ActionPage,
          org_id: org.id,
          campaign_id: campaign.id,
          name: name) || %ActionPage{})
    |> ActionPage.changeset(attrs)
    |> put_change(:campaign_id, campaign.id)
    |> put_change(:org_id, org.id)
  end

  def upsert(org, campaign, attrs) do
      %ActionPage{}
      |> ActionPage.changeset(attrs)
      |> put_change(:campaign_id, campaign.id)
      |> put_change(:org_id, org.id)
  end

  def find(id) do
    Repo.one from a in ActionPage, where: a.id == ^id, preload: [:campaign, :org]
  end

  def contact_schema(%ActionPage{campaign: %Campaign{org: %Org{contact_schema: cs}}}) do
    case cs do
      :basic -> Proca.Contact.BasicData
      :popular_initiative -> Proca.Contact.PopularInitiativeData
    end
  end

  def new_data(params, action_page) do
    schema = contact_schema(action_page)
    apply(schema, :from_input, [params])
  end
end
