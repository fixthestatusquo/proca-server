defmodule Mix.Tasks.Proca.ExportTargetMessages do
  use Mix.Task

  alias Proca.Action.MessageExport

  @shortdoc "Export messages sent to a target as CSV"

  @moduledoc """
  Exports all messages sent to one or more targets as a CSV
  and emails the list to each target address.

      mix proca.export_target_messages \\
        --target politician@example.com \\
        [--target another@example.com] \\
        [--campaign CAMPAIGN_NAME] \\
        [--target-uuid UUID] \\
        [--subject "People who contacted you"] \\
        [--message "Please find the full list attached."] \\
        [--include-duplicates] \\
        [--dry-run]

  Options:
    --target EMAIL          Target email address. Repeatable.
    --campaign NAME         Filter messages to this campaign name (when using --target).
    --target-uuid UUID      Use target UUID instead of email; scoped to one campaign.
    --subject TEXT          Subject line for the covering email (optional).
    --message TEXT          Body text for the covering email (optional).
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
          subject: :string,
          message: :string,
          include_duplicates: :boolean,
          dry_run: :boolean
        ]
      )

    targets = Keyword.get_values(opts, :target)
    campaign_filter = Keyword.get(opts, :campaign)
    target_uuid = Keyword.get(opts, :target_uuid)
    subject = Keyword.get(opts, :subject)
    message_body = Keyword.get(opts, :message)
    include_duplicates = Keyword.get(opts, :include_duplicates, false)

    if targets == [] and is_nil(target_uuid) do
      Mix.shell().error(
        "No --target or --target-uuid provided. Use: --target EMAIL or --target-uuid UUID"
      )

      exit({:shutdown, 1})
    end

    Mix.Task.run("app.start")

    org = load_instance_org()

    if target_uuid do
      process_target_by_uuid(target_uuid, org, subject, message_body, include_duplicates, dry_run)
    else
      Enum.each(targets, fn target_email ->
        process_target(target_email, campaign_filter, org, subject, message_body, include_duplicates, dry_run)
      end)
    end
  end

  defp process_target_by_uuid(target_uuid, org, subject, message_body, include_duplicates, dry_run) do
    rows = fetch_messages_by_uuid(target_uuid, include_duplicates)

    target_email =
      case rows do
        [first | _] -> first.target_email
        [] -> target_uuid
      end

    process_rows(target_email, rows, org, subject, message_body, dry_run)
  end

  defp process_target(target_email, campaign_filter, org, subject, message_body, include_duplicates, dry_run) do
    rows = fetch_messages(target_email, campaign_filter, include_duplicates)

    process_rows(target_email, rows, org, subject, message_body, dry_run)
  end

  defp process_rows(target_email, rows, org, subject, message_body, dry_run) do
    if rows == [] do
      Mix.shell().info("No messages found for #{target_email}")
      :ok
    else
      csv = build_csv(rows)
      campaigns = rows |> Enum.map(& &1.campaign_name) |> Enum.uniq() |> Enum.join(", ")

      resolved_subject = subject || "Messages sent to you (#{campaigns})"
      resolved_body = message_body || default_body(length(rows), campaigns)

      if dry_run do
        Mix.shell().info("=== #{target_email} — #{length(rows)} message(s), campaigns: #{campaigns} ===")
        IO.puts(csv)
      else
        target_name = rows |> List.first() |> Map.get(:target_name)

        case send_email(org, target_email, resolved_subject, resolved_body, csv, target_name) do
          :ok ->
            Mix.shell().info("Sent #{length(rows)}-row export to #{target_email}")

          {:error, reason} ->
            Mix.shell().error("Failed to send to #{target_email}: #{inspect(reason)}")
        end
      end
    end
  end

  defp fetch_messages(target_email, campaign_filter, include_duplicates) do
    base =
      from(m in Message,
        join: te in TargetEmail,
        on: te.target_id == m.target_id,
        join: t in assoc(m, :target),
        join: mc in assoc(m, :message_content),
        join: a in assoc(m, :action),
        join: s in assoc(a, :supporter),
        join: ap in assoc(a, :action_page),
        join: c in assoc(ap, :campaign),
        where: te.email == ^target_email,
        order_by: [asc: a.inserted_at],
        select: %{
          first_name: s.first_name,
          last_name: s.last_name,
          email: s.email,
          area: s.area,
          campaign_name: c.name,
          target_name: t.name,
          msg_subject: mc.subject,
          msg_body: mc.body,
          created_at: a.inserted_at,
          dupe_rank: m.dupe_rank
        }
      )

    base =
      if campaign_filter do
        where(base, [..., c], c.name == ^campaign_filter)
      else
        base
      end

    query =
      if include_duplicates do
        base
      else
        where(base, [m], m.dupe_rank == 0)
      end

    Repo.all(query)
  end

  defp fetch_messages_by_uuid(target_uuid, include_duplicates) do
    base =
      from(m in Message,
        join: te in TargetEmail,
        on: te.target_id == m.target_id,
        join: t in assoc(m, :target),
        join: mc in assoc(m, :message_content),
        join: a in assoc(m, :action),
        join: s in assoc(a, :supporter),
        join: ap in assoc(a, :action_page),
        join: c in assoc(ap, :campaign),
        where: m.target_id == ^target_uuid,
        order_by: [asc: a.inserted_at],
        select: %{
          first_name: s.first_name,
          last_name: s.last_name,
          email: s.email,
          area: s.area,
          campaign_name: c.name,
          target_name: t.name,
          target_email: te.email,
          msg_subject: mc.subject,
          msg_body: mc.body,
          created_at: a.inserted_at,
          dupe_rank: m.dupe_rank
        }
      )

    query =
      if include_duplicates do
        base
      else
        where(base, [m], m.dupe_rank == 0)
      end

    Repo.all(query)
  end
end
