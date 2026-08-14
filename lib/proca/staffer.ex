defmodule Proca.Staffer do
  @moduledoc """
  Join table between Org and User. Means that user has a role/some permissions in an Org.
  """
  use Ecto.Schema
  import Ecto.Changeset
  use Proca.Schema, module: __MODULE__
  alias Proca.Repo
  alias Proca.Users.User
  alias Proca.Staffer
  import Ecto.Query, only: [from: 2, where: 3, preload: 2, distinct: 2]

  schema "staffers" do
    field :perms, :integer, default: 0
    field :last_signin_at, :utc_datetime
    belongs_to :org, Proca.Org
    belongs_to :user, Proca.Users.User

    timestamps()
  end

  @doc false
  def changeset(staffer, attrs) do
    attrs = normalize_perms(attrs)
    assocs = Map.take(attrs, [:org, :user])

    staffer
    |> cast(attrs, [:perms, :last_signin_at, :org_id, :user_id])
    |> change(assocs)
    |> validate_required([:perms])
    |> unique_constraint([:org_id, :user_id])
  end

  def changeset(attrs), do: changeset(%Staffer{}, attrs)

  def normalize_perms(params = %{role: _role}) do
    {role, params} = Map.pop(params, :role)
    bits = Proca.Permission.add(0, Staffer.Role.permissions(role))
    Map.put(params, :perms, bits)
  end

  def normalize_perms(params = %{perms: perms}) when is_list(perms) do
    %{params | perms: Proca.Permission.add(0, perms)}
  end

  def normalize_perms(params), do: params

  def all(q, [:preload | kw]), do: preload(q, [:user, :org]) |> all(kw)

  def all(q, [{:org, org} | kw]), do: where(q, [s], s.org_id == ^org.id) |> all(kw)
  def all(q, [{:user, user} | kw]), do: where(q, [s], s.user_id == ^user.id) |> all(kw)

  # XXX rewrite
  def for_user_in_org(%User{id: id}, org_name) when is_bitstring(org_name) do
    from(s in Staffer,
      join: o in assoc(s, :org),
      where: s.user_id == ^id and o.name == ^org_name,
      preload: [org: o]
    )
    |> Repo.one()
  end

  def for_user_in_org(%User{id: id}, org_id) when is_integer(org_id) do
    from(s in Staffer,
      join: o in assoc(s, :org),
      where: s.user_id == ^id and o.id == ^org_id,
      preload: [org: o]
    )
    |> Repo.one()
  end

  def for_user(%User{id: id}) do
    from(s in Staffer,
      join: o in assoc(s, :org),
      where: s.user_id == ^id,
      order_by: [desc: :last_signin_at],
      preload: [org: o],
      limit: 1
    )
    |> Repo.one()
  end

  def get_by_org(org_id, preload \\ [:user]) when is_integer(org_id) do
    Proca.Repo.all(from s in Proca.Staffer, where: s.org_id == ^org_id, preload: ^preload)
  end

  @spec not_in_org(any) :: any
  def not_in_org(org_id) do
    from(u in User,
      left_join: st in Staffer,
      on: u.id == st.user_id and st.org_id == ^org_id,
      where: is_nil(st.id)
    )
    |> distinct(true)
    |> Repo.all()
  end
end
