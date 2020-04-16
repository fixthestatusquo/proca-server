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

if !Proca.Repo.get_by(Proca.Org, name: org_name) do
  IO.puts "Seeding DB with #{org_name} Org."
  {:ok, org} = Proca.Repo.insert(%Proca.Org{name: org_name, title: org_name})
  Proca.PublicKey.build_for(org, "seeded keys") |> Proca.Repo.insert()
end
