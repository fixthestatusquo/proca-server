defmodule Proca.Supporter.RetentionCleanup do
  @moduledoc """
  Maintenance helpers for deleting retained org contact data.
  """

  import Ecto.Query

  alias Proca.{Action, Campaign, Contact, Org, Repo, Supporter}

  @default_months 24
  @processed_statuses [:accepted, :delivered]
  @supporter_pii_fields [first_name: nil, last_name: nil, email: nil, address: nil]

  def default_months, do: @default_months

  def run(org_or_name, mode, opts \\ []) do
    dry_run = Keyword.get(opts, :dry_run, false)

    with {:ok, org} <- fetch_org(org_or_name),
         {:ok, mode} <- validate_mode(mode),
         {:ok, months} <- validate_months(Keyword.get(opts, :months, @default_months)) do
      queries = cleanup_queries(org.id, months)
      contacts_count = Repo.aggregate(queries.contacts, :count, :id)

      supporters_count =
        case mode do
          :remove_pii -> Repo.aggregate(queries.supporters, :count, :id)
          :delete_contacts -> 0
        end

      result = %{
        dry_run: dry_run,
        mode: mode,
        months: months,
        org_name: org.name,
        contacts_count: contacts_count,
        supporters_count: supporters_count
      }

      if dry_run do
        {:ok, result}
      else
        case Repo.transaction(fn ->
               if mode == :remove_pii and supporters_count > 0 do
                 Repo.update_all(queries.supporters, set: @supporter_pii_fields)
               end

               if contacts_count > 0 do
                 Repo.delete_all(queries.contacts)
               end
             end) do
          {:ok, _} -> {:ok, result}
          {:error, reason} -> {:error, inspect(reason)}
        end
      end
    end
  end

  defp cleanup_queries(org_id, months) do
    supporter_ids = eligible_supporter_ids_query(org_id, months)

    %{
      supporters: from(s in Supporter, where: s.id in subquery(supporter_ids)),
      contacts:
        from(c in Contact,
          where: c.org_id == ^org_id and c.supporter_id in subquery(supporter_ids)
        )
    }
  end

  defp eligible_supporter_ids_query(org_id, months) do
    from(s in Supporter,
      join: c in Contact,
      on: c.supporter_id == s.id and c.org_id == ^org_id,
      join: a in Action,
      on: a.supporter_id == s.id,
      join: campaign in Campaign,
      on: campaign.id == a.campaign_id,
      where: s.processing_status in ^@processed_statuses,
      group_by: s.id,
      having:
        fragment(
          "bool_and(?)",
          a.processing_status in ^@processed_statuses and
            campaign.status == ^:closed and
            a.inserted_at < ago(^months, "month")
        ),
      select: s.id
    )
  end

  defp fetch_org(%Org{} = org), do: {:ok, org}

  defp fetch_org(org_name) when is_binary(org_name) do
    case Org.one(name: org_name) do
      %Org{} = org -> {:ok, org}
      nil -> {:error, "no such org #{org_name}"}
    end
  end

  defp validate_mode(mode) when mode in [:delete_contacts, :remove_pii], do: {:ok, mode}

  defp validate_mode("delete_contacts"), do: {:ok, :delete_contacts}
  defp validate_mode("remove_pii"), do: {:ok, :remove_pii}
  defp validate_mode(_), do: {:error, "mode must be delete_contacts or remove_pii"}

  defp validate_months(months) when is_integer(months) and months > 0, do: {:ok, months}

  defp validate_months(months) when is_binary(months) do
    case Integer.parse(months) do
      {parsed, ""} -> validate_months(parsed)
      _ -> {:error, "months must be a positive integer"}
    end
  end

  defp validate_months(_), do: {:error, "months must be a positive integer"}
end
