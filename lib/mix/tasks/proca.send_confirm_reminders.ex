defmodule Mix.Tasks.Proca.SendConfirmReminders do
  use Mix.Task

  alias Proca.Supporter.ConfirmReminder

  @shortdoc "Send confirmation reminder emails to unconfirmed supporters"

  @moduledoc """
  Sends confirmation reminder emails to supporters stuck in :confirming state.

  Per-org reminder config (org.config["reminder"]):
    - "enabled"              - must be true (opt-in)
    - "reminder_delays_days" - list of day offsets from inserted_at (default [2])
    - "max_age_days"         - ignore actions older than this (default 30)

  ## Options

    --dry-run   Show who would receive reminders without sending anything

  ## Examples

      mix proca.send_confirm_reminders
      mix proca.send_confirm_reminders --dry-run

  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} = OptionParser.parse(args, strict: [dry_run: :boolean])

    if opts[:dry_run] do
      dry_run()
    else
      Mix.shell().info("Sending confirmation reminders...")
      ConfirmReminder.run()
      Mix.shell().info("Done.")
    end
  end

  defp dry_run do
    due = ConfirmReminder.list_due()

    if due == [] do
      Mix.shell().info("No reminders due.")
    else
      total = Enum.sum(Enum.map(due, fn {_org, actions} -> length(actions) end))
      Mix.shell().info("#{total} reminder(s) would be sent:\n")

      Enum.each(due, fn {org, actions} ->
        Mix.shell().info("  #{org.name} (#{length(actions)} action(s)):")

        Enum.each(actions, fn action ->
          Mix.shell().info(
            "    action #{action.id} — #{action.supporter.email} (reminder_count=#{action.reminder_count}, inserted_at=#{action.inserted_at})"
          )
        end)
      end)
    end
  end
end
