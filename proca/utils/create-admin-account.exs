defmodule Proca.CreateAdminAccount do
  def main(argv) do
    argv
    |> parse_args()
  end

  defp parse_args(args) do
    {options, args, errors} = OptionParser.parse(args, switches: [help: :boolean, org: :integer])

    case {options, args, errors} do
      {[help: true], _, _} -> help()
      {[], [], _} -> help()
      {[org: org], [email], []} -> create(email, org) # , org)
      {[], [email], []} -> create(email)
    end
  end

  defp create(email) do
    org = hd Proca.Org.list()
    create(email, org.id)
  end

  defp create(email, org_id) do
    # if is_integer(org) do
    #   IO.puts("Looking up org #{org}")
    #   # org = Proca.Repo.get_by(Proca.Org, id: org)
    org = Proca.Org.get_by_id(org_id)
    # else
    #   IO.puts("org #{org} is not an int")
    # end

    user = Proca.Repo.get_by(Proca.Users.User, email: email)
    user = if user do
      IO.puts("User already exists - I'll grant admin permission, but won't reset the password")
      user
    else
      Proca.Users.User.create(email)
    end

    case user do
      nil -> IO.puts("I couldn't create or find a user with email \"#{email}\". Is it really an email?")
      %Proca.Users.User{} -> _create_admin(user, org)
    end
  end

  defp _find_staffer(user, org)
  do
    staffer = Proca.Staffer.for_user_in_org(user, org.id)
    case staffer
    do
      nil -> _create_staffer(user, org)
      _   -> staffer
    end
  end

  defp _create_staffer(user, org)
  do
    Proca.Staffer.build_for_user(user, org.id, [])
    |> Ecto.Changeset.apply_changes()
  end

  defp _create_admin(user, org) do

    staffer = _find_staffer(user, org)

    staffer
    |> Proca.Repo.preload(:user)
    |> Proca.Staffer.Role.change(:admin)
    |> Proca.Repo.insert!()

    IO.puts("""

    Welcome to #{org.title}

    URL: ????

    Login: #{user.email}
    Password: #{user.password || "** Existing user **"}

    """)
  end

  defp help() do
    IO.puts("""
Usage: mix run util/create-admin-account.exs [--help] [--org ID] email

Create an admin account with the email given. A password will
be randomly generated and printed.

OPTIONS

  --help      Print this help
  --org       Use this organization for the User, defaults to the first Organization found.

ARGS

  email       Email of the new user.
""")
  end
end


Proca.CreateAdminAccount.main(System.argv())
