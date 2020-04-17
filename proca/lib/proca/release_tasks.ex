defmodule Proca.ReleaseTasks do
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
    load_and_run(fn _ ->
      # Run migrations
      Enum.each(@myapps, &run_migrations_for/1)
    end)
  end

  def seed do
    load_and_run(fn _ ->
      # Run the seed script if it exists
      seed_script = seed_path(:proca)
      if File.exists?(seed_script) do
        IO.puts "Running seed script.."
        Code.eval_file(seed_script)
      end
    end)
  end

  def load_and_run(func) do
    IO.puts "Loading myapp.."
    # Load the code for myapp, but don't start it
    :ok = case Application.load(:proca) do
            :ok -> :ok
            {:error, {:already_loaded, _}} -> :ok
            _ -> :error
    end

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for myapp
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 2)))

    apply(func, [nil])

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Ecto.Migrator.run(Proca.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
  defp seed_path(app), do: Path.join([priv_dir(app), "repo", "seeds.exs"])

end
