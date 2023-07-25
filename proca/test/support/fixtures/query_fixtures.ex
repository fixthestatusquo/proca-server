defmodule Proca.QueryFixtures do
  def invite_user(%{org_name: org_name}) do
    """
    mutation {
      inviteOrgUser(orgName: "#{org_name}", message: "Welcome to our team", input: {email: "foo@example.com", role: "translator"})  {
        code email objectId message
      }
    }
    """
  end

  def add_campaign(%{org_name: org_name}) do
    """
    mutation {
      addCampaign(orgName: "#{org_name}", input: {title: "campaign", name: "campaign"}) {
        id
      }
    }
    """
  end

  def update_action_page(%{action_page_id: id}) do
    """
    mutation {
      updateActionPage(id: #{id}, input: {locale: "pl"}) {
        id
      }
    }
    """
  end

  def export_actions(%{org_name: org_name}) do
    """
    query {
      exportActions(orgName: "#{org_name}") {
        actionId
      }
    }
    """
  end
end
