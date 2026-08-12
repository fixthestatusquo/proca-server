defmodule ProcaWeb.Api.DeleteContactTest do
  use ProcaWeb.ConnCase

  import Ecto.Query
  import Proca.StoryFactory, only: [red_story: 0]
  import Proca.Permission, only: [remove: 2]

  alias Ecto.Changeset
  alias Proca.{Contact, Factory, Repo, Supporter}

  setup do
    story = red_story()

    action =
      Factory.insert(:action,
        action_page: story.yellow_ap,
        processing_status: :delivered,
        supporter_processing_status: :accepted
      )

    %{
      action: action,
      contact_ref: Supporter.base_encode(action.supporter.fingerprint)
    }
    |> Map.merge(story)
  end

  test "org owner can delete contact without crashing", %{
    conn: conn,
    yellow_org: org,
    yellow_user: owner,
    action: action,
    contact_ref: contact_ref
  } do
    supporter_id = action.supporter.id

    assert contact_count(supporter_id, org.id) == 1

    res =
      conn
      |> auth_api_post(delete_contact_query(org.name, contact_ref), owner)
      |> json_response(200)
      |> is_success()

    assert res["data"]["deleteContact"] == "SUCCESS"

    supporter = Repo.get!(Supporter, supporter_id)

    assert supporter.first_name == nil
    assert supporter.last_name == nil
    assert supporter.email == nil
    assert supporter.address == nil
    assert contact_count(supporter_id, org.id) == 0
  end

  test "non-owner cannot delete contact", %{
    conn: conn,
    yellow_org: org,
    yellow_campaigner_user: user,
    action: action,
    contact_ref: contact_ref
  } do
    supporter_id = action.supporter.id
    before_supporter = Repo.get!(Supporter, supporter_id)

    res =
      conn
      |> auth_api_post(delete_contact_query(org.name, contact_ref), user)
      |> json_response(200)

    assert %{
             "errors" => [
               %{
                 "extensions" => %{
                   "code" => "permission_denied"
                 }
               }
             ]
           } = res

    assert contact_count(supporter_id, org.id) == 1

    supporter = Repo.get!(Supporter, supporter_id)

    assert supporter.first_name == before_supporter.first_name
    assert supporter.last_name == before_supporter.last_name
    assert supporter.email == before_supporter.email
    assert supporter.address == before_supporter.address
  end

  test "legacy owner without delete permission cannot delete contact", %{
    conn: conn,
    yellow_org: org,
    yellow_user: user,
    yellow_owner: owner,
    action: action,
    contact_ref: contact_ref
  } do
    owner
    |> Changeset.change(perms: remove(owner.perms, :delete_contacts))
    |> Repo.update!()

    supporter_id = action.supporter.id
    before_supporter = Repo.get!(Supporter, supporter_id)

    res =
      conn
      |> auth_api_post(delete_contact_query(org.name, contact_ref), user)
      |> json_response(200)

    assert %{
             "errors" => [
               %{
                 "extensions" => %{
                   "code" => "permission_denied"
                 }
               }
             ]
           } = res

    assert contact_count(supporter_id, org.id) == 1

    supporter = Repo.get!(Supporter, supporter_id)

    assert supporter.first_name == before_supporter.first_name
    assert supporter.last_name == before_supporter.last_name
    assert supporter.email == before_supporter.email
    assert supporter.address == before_supporter.address
  end

  defp delete_contact_query(org_name, contact_ref) do
    """
    mutation {
      deleteContact(orgName: "#{org_name}", contactRef: "#{contact_ref}")
    }
    """
  end

  defp contact_count(supporter_id, org_id) do
    Repo.aggregate(
      from(c in Contact, where: c.supporter_id == ^supporter_id and c.org_id == ^org_id),
      :count,
      :id
    )
  end
end
