defmodule Mix.Tasks.Proca.ResendConfirmEmail do
  use Mix.Task

  alias Proca.Supporter.ConfirmReminder

  @shortdoc "Resend the confirmation email to unconfirmed supporters"

  @moduledoc """
  Resends the supporter-confirm email to supporters stuck in :confirming state,
  bypassing the automatic reminder's enabled/delay_days/max_count gating in
  Proca.Supporter.ConfirmReminder. Use this to recover from a batch of lost or
  unsent transactional confirmation emails.

  ## Options

    --org NAME         organisation name (required)
    --campaign NAME     campaign name (optional, restricts to one campaign)
    --since-days N       only actions taken in the last N days (optional)
    --dry-run            show who would receive the email without sending

  ## Examples

      mix proca.resend_confirm_email --org my_org --dry-run
      mix proca.resend_confirm_email --org my_org --campaign my_campaign --since-days 7
  """

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")

    {opts, _, _} =
      OptionParser.parse(args,
        strict: [org: :string, campaign: :string, since_days: :integer, dry_run: :boolean]
      )

    org_name = opts[:org] || Mix.raise("--org is required")

    query_opts =
      [org: org_name, campaign: opts[:campaign], since_days: opts[:since_days]]
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)

    if opts[:dry_run] do
      dry_run(query_opts)
    else
      {org, actions} = ConfirmReminder.resend_unconfirmed(query_opts)
      Mix.shell().info("Sent #{length(actions)} confirmation email(s) for #{org.name}.")
    end
  end

  defp dry_run(query_opts) do
    {org, actions} = ConfirmReminder.list_unconfirmed(query_opts)
    Mix.shell().info("#{length(actions)} email(s) would be sent for #{org.name}:\n")

    Enum.each(actions, fn a ->
      Mix.shell().info(
        "  action #{a.id} — #{a.supporter.email} (inserted_at=#{a.inserted_at})"
      )
    end)
  end
end
