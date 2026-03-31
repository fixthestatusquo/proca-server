defmodule Proca.Supporter.RetentionCleanupTest do
  use Proca.DataCase, async: true

  import Ecto.Changeset
  import Ecto.Query
  import Proca.StoryFactory, only: [blue_story: 0, teal_story: 1]

  alias Proca.{Action, Contact, Repo, Supporter}
  alias Proca.Contact.Data
  alias Proca.Supporter.Privacy
  alias Proca.Supporter.RetentionCleanup

  @old_inserted_at ~N[2020-01-01 00:00:00]

  test "dry run reports eligible contacts without deleting them" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()
    action = insert_processed_action(page)
    close_campaign(campaign)
    age_action(action, @old_inserted_at)

    assert {:ok, result} = RetentionCleanup.run(org.name, :delete_contacts, dry_run: true)
    assert result.dry_run
    assert result.contacts_count == 1
    assert result.supporters_count == 0

    assert contacts_for_org(action.supporter_id, org.id) == 1
    assert fetch_supporter(action.supporter_id).email
  end

  test "delete_contacts deletes eligible org contacts and keeps supporter cleartext" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()
    action = insert_processed_action(page)
    close_campaign(campaign)
    age_action(action, @old_inserted_at)

    assert {:ok, result} = RetentionCleanup.run(org.name, :delete_contacts, months: 6)
    assert result.contacts_count == 1
    assert result.supporters_count == 0

    assert contacts_for_org(action.supporter_id, org.id) == 0
    assert fetch_supporter(action.supporter_id).email
    assert fetch_supporter(action.supporter_id).first_name
  end

  test "remove_pii deletes eligible contacts and clears supporter fields" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()
    action = insert_processed_action(page)
    close_campaign(campaign)
    age_action(action, @old_inserted_at)

    assert {:ok, result} = RetentionCleanup.run(org.name, :remove_pii, months: 6)
    assert result.contacts_count == 1
    assert result.supporters_count == 1

    assert contacts_for_org(action.supporter_id, org.id) == 0

    supporter = fetch_supporter(action.supporter_id)
    assert is_nil(supporter.email)
    assert is_nil(supporter.first_name)
  end

  test "cleanup skips supporters with newer follow-up action data on the same supporter" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()
    old_action = insert_processed_action(page)
    close_campaign(campaign)
    age_action(old_action, @old_inserted_at)

    supporter = Repo.preload(fetch_supporter(old_action.supporter_id), action_page: :campaign)

    Factory.insert(:action,
      supporter: supporter,
      action_page: page,
      campaign: page.campaign,
      processing_status: :delivered
    )

    assert {:ok, result} = RetentionCleanup.run(org.name, :remove_pii, months: 6)
    assert result.contacts_count == 0
    assert result.supporters_count == 0

    assert contacts_for_org(old_action.supporter_id, org.id) == 1
    assert fetch_supporter(old_action.supporter_id).email
  end

  test "cleanup skips older supporter rows when the same fingerprint has newer selected-org action data" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()

    old_supporter = insert_supporter_with_contacts(page, %Privacy{opt_in: true})
    old_action = insert_action_for_supporter(old_supporter, page)

    close_campaign(campaign)
    age_action(old_action, @old_inserted_at)

    newer_supporter = insert_supporter_with_contacts(page, %Privacy{opt_in: true}, old_supporter)
    _newer_action = insert_action_for_supporter(newer_supporter, page)

    assert old_supporter.fingerprint == newer_supporter.fingerprint

    assert {:ok, result} = RetentionCleanup.run(org.name, :remove_pii, months: 6)
    assert result.contacts_count == 0
    assert result.supporters_count == 0

    assert contacts_for_org(old_supporter.id, org.id) == 1
    assert contacts_for_org(newer_supporter.id, org.id) == 1
    assert fetch_supporter(old_supporter.id).email
    assert fetch_supporter(newer_supporter.id).email
  end

  test "cleanup skips supporters on closed campaigns with recent end date" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()
    action = insert_processed_action(page)
    Repo.update!(change(campaign, status: :closed, end: Date.utc_today()))
    age_action(action, @old_inserted_at)

    assert {:ok, result} = RetentionCleanup.run(org.name, :remove_pii, months: 6)
    assert result.contacts_count == 0
    assert result.supporters_count == 0

    assert contacts_for_org(action.supporter_id, org.id) == 1
    assert fetch_supporter(action.supporter_id).email
  end

  test "cleanup is scoped to contacts owned by the selected org in coalition campaigns" do
    %{org: lead_org, campaign: campaign, partners: [%{org: partner_org, page: partner_page}]} =
      teal_story(partner_count: 1)

    partner_page = Repo.update!(change(partner_page, delivery: false))
    close_campaign(campaign)

    supporter = insert_supporter_with_contacts(partner_page, %Privacy{opt_in: true, lead_opt_in: true})
    action = insert_action_for_supporter(supporter, partner_page)
    age_action(action, @old_inserted_at)

    assert contacts_for_org(supporter.id, partner_org.id) == 1
    assert contacts_for_org(supporter.id, lead_org.id) == 1

    assert {:ok, result} = RetentionCleanup.run(lead_org.name, :delete_contacts, months: 6)
    assert result.contacts_count == 1
    assert result.supporters_count == 0

    assert contacts_for_org(supporter.id, lead_org.id) == 0
    assert contacts_for_org(supporter.id, partner_org.id) == 1
  end

  test "remove_pii keeps supporter cleartext when other org contacts remain in a coalition campaign" do
    %{org: lead_org, campaign: campaign, partners: [%{org: partner_org, page: partner_page}]} =
      teal_story(partner_count: 1)

    partner_page = Repo.update!(change(partner_page, delivery: false))
    close_campaign(campaign)

    supporter = insert_supporter_with_contacts(partner_page, %Privacy{opt_in: true, lead_opt_in: true})
    action = insert_action_for_supporter(supporter, partner_page)
    age_action(action, @old_inserted_at)

    assert {:ok, result} = RetentionCleanup.run(lead_org.name, :remove_pii, months: 6)
    assert result.contacts_count == 1
    assert result.supporters_count == 0

    assert contacts_for_org(supporter.id, lead_org.id) == 0
    assert contacts_for_org(supporter.id, partner_org.id) == 1

    supporter = fetch_supporter(supporter.id)
    assert supporter.email
    assert supporter.first_name
  end

  defp insert_processed_action(action_page) do
    Factory.insert(:action,
      action_page: action_page,
      supporter_processing_status: :accepted,
      processing_status: :delivered
    )
  end

  defp insert_supporter_with_contacts(action_page, privacy, existing_supporter \\ nil) do
    data =
      case existing_supporter do
        nil -> nil
        supporter -> contact_data_from_supporter(supporter)
      end

    {supporter, contact} =
      if data do
        {
          Supporter.new_supporter(data, action_page),
          Data.to_contact(data, action_page)
        }
      else
        {
          change(%Supporter{}, Factory.params_for(:basic_data_pl_supporter, action_page: action_page)),
          change(%Contact{}, Factory.params_for(:basic_data_pl_contact, action_page: action_page))
        }
      end

    {:ok, supporter} =
      Supporter.add_contacts(
        supporter,
        contact,
        action_page,
        privacy
      )
      |> Repo.insert()

    Repo.update!(change(supporter, processing_status: :accepted))
  end

  defp insert_action_for_supporter(supporter, action_page) do
    supporter = Repo.preload(supporter, action_page: :campaign)

    Factory.insert(:action,
      supporter: supporter,
      action_page: action_page,
      campaign: action_page.campaign,
      processing_status: :delivered
    )
  end

  defp close_campaign(campaign) do
    Repo.update!(change(campaign, status: :closed, end: ~D[2020-01-01]))
  end

  defp age_action(action, inserted_at) do
    Repo.update_all(from(a in Action, where: a.id == ^action.id),
      set: [inserted_at: inserted_at, updated_at: inserted_at]
    )
  end

  defp contacts_for_org(supporter_id, org_id) do
    Repo.aggregate(
      from(c in Contact, where: c.supporter_id == ^supporter_id and c.org_id == ^org_id),
      :count,
      :id
    )
  end

  defp contact_data_from_supporter(supporter) do
    %Proca.Contact.BasicData{
      first_name: supporter.first_name,
      last_name: supporter.last_name,
      email: supporter.email,
      country: "pl",
      postcode: "02-123"
    }
  end

  defp fetch_supporter(id), do: Repo.get!(Supporter, id)
end
