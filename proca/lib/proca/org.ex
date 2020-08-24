defmodule Proca.Org do
  @moduledoc """
  Represents an organisation in Proca. `Org` can have many `Staffers`, `Campaigns` and `ActionPage`'s.

  Org can have one or more `PublicKey`'s. Only one of them is active at a particular time. Others are expired.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "orgs" do
    field :name, :string
    field :title, :string
    has_many :public_keys, Proca.PublicKey, on_delete: :delete_all
    has_many :staffers, Proca.Staffer, on_delete: :delete_all
    has_many :campaigns, Proca.Campaign, on_delete: :nilify_all
    has_many :action_pages, Proca.ActionPage, on_delete: :nilify_all

    field :contact_schema, ContactSchema, default: :basic
    
    # services and delivery options
    has_many :services, Proca.Service, on_delete: :delete_all

    field :custom_supporter_confirm, :boolean
    field :custom_action_confirm, :boolean
    field :custom_action_deliver, :boolean
    field :system_sqs_deliver, :boolean

    timestamps()
  end

  @doc false
  def changeset(org, attrs) do
    org
    |> cast(attrs, [:name, :title])
    |> validate_required([:name, :title])
    |> validate_format(:name, ~r/^([\w\d_-]+$)/)
  end

  def get_by_name(name, preload \\ []) do
    Proca.Repo.one from o in Proca.Org, where: o.name == ^name, preload: ^preload
  end

  def get_by_id(id, preload \\ []) do
    Proca.Repo.one from o in Proca.Org, where: o.id == ^id, preload: ^preload
  end

  def list(preloads \\ []) do
    Proca.Repo.all from o in Proca.Org, preload: ^preloads
  end

  @spec active_public_keys([Proca.PublicKey]) :: [Proca.PublicKey]
  def active_public_keys(public_keys) do
    public_keys
    |> Enum.filter(fn pk -> is_nil(pk.expired_at) end)
    |> Enum.sort(fn a, b -> a.inserted_at < b.inserted_at end)
  end

  @spec active_public_keys(Proca.Org) :: Proca.PublicKey | nil
  def active_public_key(org) do
    org = Proca.Repo.preload(org, [:public_keys])
    org.public_keys
    |> active_public_keys()
    |> List.first()
  end
end
