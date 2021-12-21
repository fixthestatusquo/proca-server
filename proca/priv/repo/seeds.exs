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

instance_org = Proca.Org.one([:instance, :active_public_keys])

create_keys = fn org ->
  Proca.PublicKey.build_for(org, "seeded keys")
  |> Ecto.Changeset.put_change(:active, true)
  |> Proca.Repo.insert()
end

create_admin = fn org, username ->
  user =
    Proca.Users.get_user_by_email(username) ||
      Proca.Users.register_user_from_sso!(%{email: username})

  {:ok, user} = Proca.Users.User.update(Ecto.Changeset.change(user), [:admin, :generate_password])

  IO.puts("#####")
  IO.puts("#####   Created Admin user #{username}  #####")
  IO.puts("#####   Password: #{user.password}")
  IO.puts("#####")

  Proca.Org.changeset(org, %{email_from: username})
  |> Proca.Repo.update!()
end

instance_org =
  if is_nil(instance_org) do
    IO.puts("Seeding DB with #{org_name} Org.")
    {:ok, instance_org} = Proca.Repo.insert(%Proca.Org{name: org_name, title: org_name})

    create_keys.(instance_org)

    instance_org
  else
    case Proca.Org.active_public_keys(instance_org.public_keys) do
      [%Proca.PublicKey{private: p} = pk | _] when not is_nil(p) -> {:ok, pk}
      [] -> create_keys.(instance_org)
    end

    instance_org
  end

case System.get_env("ADMIN_EMAIL") do
  nil ->
    nil

  email ->
    create_admin.(instance_org, email)
end
