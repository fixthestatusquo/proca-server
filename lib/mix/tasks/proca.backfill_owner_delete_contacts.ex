defmodule Mix.Tasks.Proca.BackfillOwnerDeleteContacts do
  use Mix.Task

  alias Proca.Staffer.LegacyOwnerBackfill

  @shortdoc "Backfill delete_contacts for legacy org owners"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [apply: :boolean, org: :string]
      )

    case opts[:apply] do
      true -> apply_backfill(opts)
      _ -> dry_run(opts)
    end
  end

  defp dry_run(opts) do
    staffers = LegacyOwnerBackfill.list(org_name: opts[:org])

    Mix.shell().info("legacy owners missing delete_contacts: #{length(staffers)}")

    Enum.each(staffers, fn staffer ->
      Mix.shell().info("#{staffer.org.name}: #{staffer.user.email}")
    end)
  end

  defp apply_backfill(opts) do
    updated = LegacyOwnerBackfill.apply(org_name: opts[:org])
    Mix.shell().info("updated staffers: #{updated}")
  end
end
