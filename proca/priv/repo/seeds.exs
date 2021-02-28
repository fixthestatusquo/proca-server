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

create_keys = fn org -> 
  Proca.PublicKey.build_for(org, "seeded keys") 
  |> Ecto.Changeset.put_change(:active, true)
  |> Proca.Repo.insert()
  end

create_admin = fn org, username ->
  user = Proca.Users.User.create(username) || Proca.Repo.get_by( Proca.Users.User, email: username)

  Proca.Staffer.build_for_user(user, org.id, [])
  |> Ecto.Changeset.apply_changes()
  |> Proca.Staffer.Role.change(:admin)
  |> Proca.Repo.insert!()

  IO.puts "#####"
  IO.puts "#####   Created Admin user #{username}  #####"
  IO.puts "#####   Password: #{user.password}"
  IO.puts "#####"
  end

if is_nil(org) do
  IO.puts "Seeding DB with #{org_name} Org."
  {:ok, org} = Proca.Repo.insert(%Proca.Org{name: org_name, title: org_name})

  create_keys.(org)

  case System.get_env("ADMIN_EMAIL") do 
    nil -> nil
    email -> create_admin.(org, email)
  end
else
  case Proca.Org.active_public_keys(org.public_keys) do
    [%Proca.PublicKey{private: p} = pk | _] when not is_nil(p) -> {:ok, pk}

    [] -> create_keys.(org)
  end
end
