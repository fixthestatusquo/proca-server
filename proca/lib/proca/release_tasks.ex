defmodule Proca.ReleaseTasks do
  @moduledoc """
  Tasks to seed and migrate the db on app start
  """
  @start_apps [
    :postgrex,
    :ecto,
    :ecto_sql
  ]

  @myapps [
    :proca
  ]

  @repos [
    Proca.Repo
  ]

  def migrate do
    IO.puts "Migrate the database if necessary"
    load_and_run(fn _ ->
      # Run migrations
      Enum.each(@myapps, &run_migrations_for/1)
    end)
  end

  def seed do
    IO.puts "Seeding the database (if not done already)"
    load_and_run(fn _ ->
      # Run the seed script if it exists
      seed_script = seed_path(:proca)

      if File.exists?(seed_script) do
        IO.puts("Running seed script..")
        Code.eval_file(seed_script)
      end
    end)
  end

  def load_and_run(func) do
    # Load the code for myapp, but don't start it
    :ok =
      case Application.load(:proca) do
        :ok -> :ok
        {:error, {:already_loaded, _}} -> :ok
        _ -> :error
      end

    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    Enum.each(@repos, & &1.start_link(pool_size: 2))

    apply(func, [nil])

    :init.stop()
  end

  def make_admin(email) do
    instance_org = Proca.Repo.get_by(Proca.Org, %{name: Application.get_env(:proca, Proca)[:org_name]})

    case Proca.Repo.get_by(Proca.Users.User, %{email: email}) do
      u when not is_nil(u) ->
        Proca.Staffer.build_for_user(u, instance_org.id, Proca.Staffer.Role.permissions(:admin))
        |>Proca.Repo.insert()
        IO.puts("Added #{email} as admin")
      _ -> IO.puts("Can't find user #{email}")
    end
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts("Running migrations for #{app}")
    Ecto.Migrator.run(Proca.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
  defp seed_path(app), do: Path.join([priv_dir(app), "repo", "seeds.exs"])
end
