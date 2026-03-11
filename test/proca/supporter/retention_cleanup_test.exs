defmodule Proca.Supporter.RetentionCleanupTest do
  use Proca.DataCase, async: true

  import Ecto.Changeset
  import Ecto.Query
  import Proca.StoryFactory, only: [blue_story: 0, teal_story: 1]

  alias Proca.{Action, Contact, Repo, Supporter}
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

  test "cleanup skips supporters with newer action data" do
    %{org: org, pages: [page], campaign: campaign} = blue_story()
    old_action = insert_processed_action(page)
    close_campaign(campaign)
    age_action(old_action, @old_inserted_at)

    Factory.insert(:action,
      supporter: fetch_supporter(old_action.supporter_id),
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

  defp insert_processed_action(action_page) do
    Factory.insert(:action,
      action_page: action_page,
      supporter_processing_status: :accepted,
      processing_status: :delivered
    )
  end

  defp insert_supporter_with_contacts(action_page, privacy) do
    contact = Factory.params_for(:basic_data_pl_contact, action_page: action_page)
    supporter = Factory.params_for(:basic_data_pl_supporter, action_page: action_page)

    {:ok, supporter} =
      Supporter.add_contacts(
        change(%Supporter{}, supporter),
        change(%Contact{}, contact),
        action_page,
        privacy
      )
      |> Repo.insert()

    Repo.update!(change(supporter, processing_status: :accepted))
  end

  defp insert_action_for_supporter(supporter, action_page) do
    Factory.insert(:action,
      supporter: supporter,
      action_page: action_page,
      campaign: action_page.campaign,
      processing_status: :delivered
    )
  end

  defp close_campaign(campaign) do
    Repo.update!(change(campaign, status: :closed))
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

  defp fetch_supporter(id), do: Repo.get!(Supporter, id)
end
