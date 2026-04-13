defmodule Proca.Supporter.RetentionCleanup do
  @moduledoc """
  Maintenance helpers for deleting retained org contact data.
  """

  import Ecto.Query

  alias Proca.{Action, ActionPage, Campaign, Contact, Org, Repo, Supporter}

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
    contacts = deletable_contacts_query(supporter_ids, org_id)
    supporter_ids_to_clear = supporter_ids_to_clear_query(supporter_ids, contacts)

    %{
      supporters: from(s in Supporter, where: s.id in subquery(supporter_ids_to_clear)),
      contacts: contacts
    }
  end

  defp eligible_supporter_ids_query(org_id, months) do
    candidate_supporters = candidate_supporters_query(org_id, months)
    protected_fingerprints = protected_fingerprints_query(org_id, months)

    from(candidate in subquery(candidate_supporters),
      left_join: protected in subquery(protected_fingerprints),
      on: protected.fingerprint == candidate.fingerprint,
      where: is_nil(protected.fingerprint),
      select: candidate.id
    )
  end

  defp candidate_supporters_query(org_id, months) do
    from(s in Supporter,
      join: ap in ActionPage,
      on: ap.id == s.action_page_id,
      join: c in Contact,
      on:
        c.supporter_id == s.id and
          (c.org_id == ^org_id or
             (ap.org_id == ^org_id and c.org_id != ^org_id and c.communication_consent == false)),
      join: a in Action,
      on: a.supporter_id == s.id,
      join: campaign in Campaign,
      on: campaign.id == a.campaign_id,
      where: s.processing_status in ^@processed_statuses,
      group_by: [s.id, s.fingerprint],
      having:
        fragment(
          "bool_and(?)",
          a.processing_status in ^@processed_statuses and
            campaign.status == ^:closed and
            campaign.end < ago(^months, "month") and
            a.inserted_at < ago(^months, "month")
        ),
      select: %{id: s.id, fingerprint: s.fingerprint}
    )
  end

  defp protected_fingerprints_query(org_id, months) do
    from(s in Supporter,
      join: ap in ActionPage,
      on: ap.id == s.action_page_id,
      join: c in Contact,
      on:
        c.supporter_id == s.id and
          (c.org_id == ^org_id or
             (ap.org_id == ^org_id and c.org_id != ^org_id and c.communication_consent == false)),
      join: a in Action,
      on: a.supporter_id == s.id,
      join: campaign in Campaign,
      on: campaign.id == a.campaign_id,
      where:
        not (a.processing_status in ^@processed_statuses and
               campaign.status == ^:closed and
               campaign.end < ago(^months, "month") and
               a.inserted_at < ago(^months, "month")),
      distinct: s.fingerprint,
      select: %{fingerprint: s.fingerprint}
    )
  end

  defp deletable_contacts_query(supporter_ids, org_id) do
    from(c in Contact,
      join: s in Supporter,
      on: s.id == c.supporter_id,
      join: ap in ActionPage,
      on: ap.id == s.action_page_id,
      join: eligible in subquery(supporter_ids),
      on: eligible.id == s.id,
      where:
        c.org_id == ^org_id or
          (ap.org_id == ^org_id and c.org_id != ^org_id and c.communication_consent == false)
    )
  end

  defp supporter_ids_to_clear_query(supporter_ids, contacts_to_delete) do
    contact_ids_to_delete =
      from(c in subquery(contacts_to_delete),
        select: %{id: c.id}
      )

    from(s in Supporter,
      join: eligible in subquery(supporter_ids),
      on: eligible.id == s.id,
      left_join: all_contacts in Contact,
      on: all_contacts.supporter_id == s.id,
      left_join: deletable_contacts in subquery(contact_ids_to_delete),
      on: deletable_contacts.id == all_contacts.id,
      group_by: s.id,
      having: count(all_contacts.id) == count(deletable_contacts.id),
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
