defmodule Mix.Tasks.Proca.ExportTargetMessages do
  use Mix.Task

  alias Proca.Action.MessageExport

  @shortdoc "Export messages sent to a target as CSV"

  @moduledoc """
  Exports all messages sent to one or more targets (across all orgs) as CSV to stdout.

      mix proca.export_target_messages \\
        --target politician@example.com \\
        [--target another@example.com] \\
        [--campaign CAMPAIGN_NAME] \\
        [--target-uuid UUID] \\
        [--include-duplicates]

  Options:
    --target EMAIL          Target email address. Repeatable.
    --campaign NAME         Filter messages to this campaign name (when using --target).
    --target-uuid UUID      Use target UUID instead of email.
    --include-duplicates    Include duplicate supporter actions (dupe_rank > 0).
  """

  @impl Mix.Task
  def run(args) do
    {opts, _, _} =
      OptionParser.parse(args,
        strict: [
          target: :keep,
          campaign: :string,
          target_uuid: :string,
          include_duplicates: :boolean
        ]
      )

    targets = Keyword.get_values(opts, :target)
    campaign_filter = Keyword.get(opts, :campaign)
    target_uuid = Keyword.get(opts, :target_uuid)
    include_duplicates = Keyword.get(opts, :include_duplicates, false)

    if targets == [] and is_nil(target_uuid) do
      Mix.shell().error(
        "No --target or --target-uuid provided. Use: --target EMAIL or --target-uuid UUID"
      )

      exit({:shutdown, 1})
    end

    Mix.Task.run("app.start")

    if target_uuid do
      case MessageExport.export_by_uuid(target_uuid, include_duplicates: include_duplicates) do
        {:ok, csv} -> IO.puts(csv)
        {:error, reason} -> Mix.shell().info(reason)
      end
    else
      Enum.each(targets, fn target_email ->
        case MessageExport.export(target_email,
               campaign_filter: campaign_filter,
               include_duplicates: include_duplicates
             ) do
          {:ok, csv} -> IO.puts(csv)
          {:error, reason} -> Mix.shell().info(reason)
        end
      end)
    end
  end
end
