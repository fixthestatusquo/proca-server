defmodule Proca.Org do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "orgs" do
    field :name, :string
    field :title, :string
    has_many :public_keys, Proca.PublicKey, on_delete: :delete_all
    has_many :staffers, Proca.Staffer, on_delete: :delete_all
    has_many :campaigns, Proca.Campaign, on_delete: :nilify_all
    has_many :action_pages, Proca.Campaign, on_delete: :nilify_all

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

  def get_public_keys(org) do
    Ecto.assoc(org, :public_keys) |> Proca.Repo.all
  end

  def list(preloads \\ []) do
    Proca.Repo.all from o in Proca.Org, preload: ^preloads
  end

  def active_public_keys(org) do
    Enum.filter(org.public_keys, fn pk -> is_nil(pk.expired_at) end)
  end
end
