defmodule Mix.Tasks.Proca.GenDbDocs do
  use Mix.Task

  @shortdoc "Regenerate the tbls database docs (guides/database) from proca_test"

  @moduledoc """
  Regenerates the generated database documentation with `tbls doc --force`.

  tbls reads its connection and output settings from `.tbls.yml`, which points at
  the local `proca_test` database. Migrate it first so the docs match the code:

      MIX_ENV=test mix ecto.migrate
      mix proca.gen_db_docs
  """
  @impl Mix.Task
  def run(_args) do
    tbls =
      System.find_executable("tbls") ||
        Mix.raise("tbls not found in PATH. See https://github.com/k1LoW/tbls")

    case System.cmd(tbls, ["doc", "--force"], into: IO.stream(), stderr_to_stdout: true) do
      {_, 0} -> Mix.shell().info("guides/database regenerated")
      {_, code} -> Mix.raise("tbls exited with status #{code}")
    end
  end
end
