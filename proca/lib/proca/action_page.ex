defmodule Proca.ActionPage do
  @moduledoc """
  Action Page belongs to a Campaign, and represents a page (widget) where members take action.

  Action Page accepts data in many formats (See Contact.Data) and produces Contact and Supporter records.
  """
  use Ecto.Schema
  use Proca.Schema, module: __MODULE__

  import Ecto.Changeset
  import Ecto.Query
  alias Ecto.Multi

  alias Proca.Repo
  alias Proca.{ActionPage, Campaign, Action, Supporter}

  schema "action_pages" do
    field :locale, :string
    field :name, :string
    field :delivery, :boolean, default: true
    field :config, :map, default: %{}
    field :live, :boolean, default: false

    belongs_to :campaign, Proca.Campaign
    belongs_to :org, Proca.Org

    field :extra_supporters, :integer, default: 0

    field :thank_you_template, :string
    field :supporter_confirm_template, :string
    # field :thank_you_template_ref, :string
    # XXX add :thank_you_template and calculate the ref via TemplateDictionary

    timestamps()
  end

  @doc """
  Casts and validates values to change an Action Page.

  The name validation is a pattern that allows two styles of action names:
  1. identifier/path1/path2/path3 - where identifiers and paths are alphanumeric + - _
  2. domain.com.pl/some/campaign - url style (very similar but _ is not allowed for domain part)
  See test/action_page_test.exs for examples of valid and invalid names
  """
  def changeset(action_page, params) do
    assocs = Map.take(params, [:org, :campaign])

    action_page
    |> cast(params, [
      :name,
      :locale,
      :extra_supporters,
      :delivery,
      :thank_you_template,
      :supporter_confirm_template,
      :config,
      :org_id,
      :campaign_id
    ])
    |> change(assocs)
    |> validate_required([:name, :locale, :extra_supporters])
    |> unique_constraint(:name)
    |> validate_inclusion(:extra_supporters, 0..100_000_000)
    |> validate_format(
      :name,
      ~r/^([[:alnum:]-_]+|[[:alnum:]-]+(?:\.[[:alnum:]\.-]+)+)(?:\/[[:alnum:]_-]+)+$/
    )
    |> validate_format(
      :locale,
      ~r/^[a-z]{2}(_[A-Z]{2})?(@[a-z]+)?$/
    )
    |> Proca.Service.EmailTemplate.validate_exists(:supporter_confirm_template)
    |> Proca.Service.EmailTemplate.validate_exists(:thank_you_template)
  end

  def changeset(attrs) do
    changeset(%ActionPage{}, attrs)
  end

  def go_live(action_page) do
    case action_page do
      %{live: true} ->
        {:ok, action_page}

      %{live: false} ->
        # XXX do the health checks!
        change(action_page, live: true) |> Repo.update_and_notify()
    end
  end

  @doc """
  Upsert query of ActionPage by id or by name.

  org - what org does it belong to
  campaign - what campaign does it belong to
  attrs - attributes. The id and name will be tried in that order to lookup existing action page. If not found, it will be created.

  XXX what about live status ? probably the upsert API needs to have an optional live=true param
  """
  def upsert(org, campaign, attrs = %{id: id}) do
    attrs = Map.merge(attrs, %{org_id: org.id, campaign_id: campaign.id})

    (Repo.get_by(ActionPage,
       org_id: org.id,
       campaign_id: campaign.id,
       id: id
     ) || %ActionPage{})
    |> ActionPage.changeset(attrs)
  end

  def upsert(org, campaign, attrs = %{name: name}) do
    attrs = Map.merge(attrs, %{org_id: org.id, campaign_id: campaign.id})

    (Repo.get_by(ActionPage,
       org_id: org.id,
       campaign_id: campaign.id,
       name: name
     ) || %ActionPage{})
    |> ActionPage.changeset(attrs)
  end

  def upsert(org, campaign, attrs) do
    attrs = Map.merge(attrs, %{org_id: org.id, campaign_id: campaign.id})

    %ActionPage{}
    |> ActionPage.changeset(attrs)
  end

  def changeset_copy(page, original, params) do
    page
    |> changeset(
      Map.take(original, [:config, :delivery, :locale, :org_id, :campaign_id])
      |> Map.merge(params)
    )
  end

  def create_copy_in(org, ap, attrs) do
    %ActionPage{}
    |> changeset_copy(ap, Map.put(attrs, :org_id, org.id))
  end

  def delete(%ActionPage{} = ap) do
    Multi.new()
    |> delete(ap)
  end

  def delete(%Multi{} = multi, %ActionPage{id: page_id} = page) do
    no_action_supporters =
      from(s in Supporter,
        select: s.id,
        left_join: a in assoc(s, :actions),
        where: s.action_page_id == ^page_id,
        group_by: s.id,
        having: count(a.id) == 0
      )

    multi
    |> Multi.delete_all(
      {:test_actions, page.id},
      from(
        a in Action,
        where: a.action_page_id == ^page.id and a.testing
      )
    )
    |> Multi.delete_all(
      {:no_action_supporters, page.id},
      from(
        s in Supporter,
        where: s.id in subquery(no_action_supporters)
      )
    )
    |> Multi.delete(
      {:action_page, page_id},
      change(page)
      |> foreign_key_constraint(:actions,
        name: :actions_action_page_id_fkey,
        message: "has action data"
      )
      |> foreign_key_constraint(:supporters,
        name: :actions_supporter_id_fkey,
        message: "has suporter data"
      )
    )
  end

  def find(id) when is_integer(id) do
    one(id: id, preload: [:campaign, :org])
  end

  def find(name) when is_bitstring(name) do
    one(name: name, preload: [:campaign, :org])
  end

  def all(q, [{:name, name} | kw]), do: where(q, [a], a.name == ^name) |> all(kw)
  def all(q, [{:url, name} | kw]), do: all(q, [{:name, name} | kw])

  def all(q, [{:org, %Proca.Org{id: org_id}} | kw]),
    do: where(q, [a], a.org_id == ^org_id) |> all(kw)

  def all(q, [{:campaign, %Proca.Campaign{id: c_id}} | kw]),
    do: where(q, [a], a.campaign_id == ^c_id) |> all(kw)

  # def all(q, [{:trash, trash} | kw]) do
  #   q
  #   |> where([ap], is_nil(ap.campaign_id) == ^trash)
  #   |> all(kw)
  # end

  def contact_schema(%ActionPage{campaign: %Campaign{contact_schema: cs}}) do
    case cs do
      :basic -> Proca.Contact.BasicData
      :popular_initiative -> Proca.Contact.PopularInitiativeData
      :eci -> Proca.Contact.EciData
      :it_ci -> Proca.Contact.ItCiData
    end
  end

  def kept_personalization_fields(%ActionPage{
        campaign: _campaign,
        org: _org
      }) do
    [:email, :first_name]
  end

  def new_data(params, action_page) do
    schema = contact_schema(action_page)
    apply(schema, :from_input, [params])
  end

  @doc """
  Get the name part before /
  """
  def name_domain(name) when is_bitstring(name) do
    [d | _] = String.split(name, "/")
    d
  end

  def location(%ActionPage{id: id}) do
    Proca.ActionPage.Status.get_last_location(id)
  end

  def name_path(name) when is_bitstring(name) do
    [_ | p] = String.split(name, "/")
    p |> Enum.join("/")
  end

  # XXX deprecated url support
  def remove_schema_from_name(name) when is_bitstring(name) do
    Regex.replace(~r/^https?:\/\//, name, "")
  end

  def thank_you_template_ref(%ActionPage{} = ap) do
    ap = Repo.preload(ap, [:org])

    case Proca.Service.EmailTemplateDirectory.by_name(ap.org, ap.thank_you_template) do
      {:ok, %{ref: ref}} when not is_nil(ref) -> ref
      _ -> ap.thank_you_template
    end
  end
end
