defmodule Mix.Tasks.Proca.ExportTargetMessages do
  use Mix.Task

  alias Proca.Action.MessageExport

  @shortdoc "Export messages sent to a target as CSV"

  @moduledoc """
  Exports all messages sent to one or more targets (across all orgs) as CSV to stdout.

      mix proca.export_target_messages \\
        --target <uuid> \\
        [--target <uuid2>] \\
        [--include-duplicates]

  Options:
    --target UUID           Target UUID. Repeatable.
    --include-duplicates    Include duplicate supporter actions (dupe_rank > 0).
  """

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          target: :keep,
          include_duplicates: :boolean
        ]
      )

    targets = Keyword.get_values(opts, :target)
    include_duplicates = Keyword.get(opts, :include_duplicates, false)

    if targets == [] do
      Mix.shell().error("No --target provided. Use: --target UUID [--target UUID2 ...]")
      exit({:shutdown, 1})
    end

    Mix.Task.run("app.start")

    Enum.each(targets, fn target_id ->
      case MessageExport.export(target_id, include_duplicates: include_duplicates) do
        {:ok, csv} -> IO.puts(csv)
        {:error, reason} -> Mix.shell().info(reason)
      end
    end)
  end
end
