defmodule Proca.Action.MessageExport do
  alias Proca.{Repo, TargetEmail}
  alias Proca.Action.Message
  import Ecto.Query

  @csv_headers [
    "first_name",
    "last_name",
    "email",
    "area",
    "campaign_name",
    "target_name",
    "msg_subject",
    "msg_body",
    "created_at"
  ]

  def export(target_email, opts \\ []) do
    include_duplicates = Keyword.get(opts, :include_duplicates, false)
    campaign_filter = Keyword.get(opts, :campaign_filter)
    rows = fetch_messages(target_email, campaign_filter, include_duplicates)

    if rows == [] do
      {:error, "No messages found for #{target_email}"}
    else
      {:ok, build_csv(rows)}
    end
  end

  def export_by_uuid(target_uuid, opts \\ []) do
    include_duplicates = Keyword.get(opts, :include_duplicates, false)
    rows = fetch_messages_by_uuid(target_uuid, include_duplicates)

    if rows == [] do
      {:error, "No messages found for target #{target_uuid}"}
    else
      {:ok, build_csv(rows)}
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
        where(base, [_m, _te, _t, _mc, _a, _s, _ap, c], c.name == ^campaign_filter)
      else
        base
      end

    query = if include_duplicates, do: base, else: where(base, [m], m.dupe_rank == 0)
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
          msg_subject: mc.subject,
          msg_body: mc.body,
          created_at: a.inserted_at,
          dupe_rank: m.dupe_rank
        }
      )

    query = if include_duplicates, do: base, else: where(base, [m], m.dupe_rank == 0)
    Repo.all(query)
  end

  defp build_csv(rows) do
    header = Enum.join(@csv_headers, ",")

    lines =
      Enum.map(rows, fn row ->
        @csv_headers
        |> Enum.map(fn key -> row[String.to_existing_atom(key)] end)
        |> Enum.map(&csv_escape/1)
        |> Enum.join(",")
      end)

    Enum.join([header | lines], "\n")
  end

  defp csv_escape(nil), do: ""
  defp csv_escape(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp csv_escape(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)

  defp csv_escape(val) when is_binary(val) do
    if String.contains?(val, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(val, "\"", "\"\"") <> "\""
    else
      val
    end
  end

  defp csv_escape(val), do: to_string(val)
end
