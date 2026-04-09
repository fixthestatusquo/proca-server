defmodule Proca.Staffer.LegacyOwnerBackfill do
  import Ecto.Query, only: [from: 2]

  alias Ecto.Changeset
  alias Proca.{Permission, Repo, Staffer}
  alias Proca.Staffer.Role

  def list(opts \\ []) do
    opts
    |> legacy_owner_query()
    |> Repo.all()
  end

  def apply(opts \\ []) do
    opts
    |> list()
    |> Enum.reduce(0, fn staffer, updated ->
      staffer
      |> Changeset.change(perms: Permission.add(staffer.perms, :delete_contacts))
      |> Repo.update!()

      updated + 1
    end)
  end

  defp legacy_owner_query(opts) do
    org_name = Keyword.get(opts, :org_name)
    legacy_owner_mask = Permission.add(0, Role.legacy_owner_permissions())
    delete_contacts_mask = Permission.add(0, :delete_contacts)

    query =
      from(s in Staffer,
      join: o in assoc(s, :org),
      join: u in assoc(s, :user),
      where: fragment("? & ? = ?", s.perms, ^legacy_owner_mask, ^legacy_owner_mask),
      where: fragment("? & ? = 0", s.perms, ^delete_contacts_mask),
      preload: [org: o, user: u],
      order_by: [asc: o.name, asc: u.email]
      )

    case org_name do
      nil -> query
      name -> from([_s, o, _u] in query, where: o.name == ^name)
    end
  end
end
