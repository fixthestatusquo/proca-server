# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Proca.Repo.insert!(%Proca.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.


org_name = Application.get_env(:proca, Proca)[:org_name]

org = Proca.Org.get_by_name(org_name, [:active_public_keys])

if is_nil(org) do
  IO.puts "Seeding DB with #{org_name} Org."
  {:ok, org} = Proca.Repo.insert(%Proca.Org{name: org_name, title: org_name})
  Proca.PublicKey.build_for(org, "seeded keys") |> Proca.Repo.insert()
else
  case Proca.Org.active_public_keys(org.public_keys) do

    [%Proca.PublicKey{private: p} = pk | _] when not is_nil(p) -> {:ok, pk}

    [] -> Proca.PublicKey.build_for(org, "seeded keys (because were missing)")
    |> Ecto.Changeset.put_change(:active, true)
    |> Proca.Repo.insert()
  end
end
