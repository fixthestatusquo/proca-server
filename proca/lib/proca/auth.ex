defmodule Proca.Auth do
  @moduledoc """
  Authorization Context for resolvers.

  We have these authorization scopes:

  - User - Refers to authenticated (by email, oauth) person. Has permissions that are instance-global. The user has an implicit permission to use the API. Admin is a special case of User (has permissions to change server settings, manage all server resoures). 
  - Staffer - Refers to org scope (has role within some org, set of permissions). The org is a namespace for resources: campaigns, action pages, services, staffers.

  Planned but not implemented:
  - Coordinator - Refers to campaign/partnership scope. This namespace contains a campaign and all its action pages (owned by different orgs).


  The authorization scopes overlap. Eg. Some Action Page can be modified by admin user, by manager staffer, or by a campaign coordinator it belongs to.

  API middleware `ProcaWeb.Resolvers.ResolveAuth` resolves the current authorization scopes based on query and its arguments.
  """
  defstruct user: nil, staffer: nil

  alias Proca.Auth
  alias Proca.{Org, Campaign, ActionPage, Staffer}
  alias Proca.Users.User

  def get_for_user(org = %Org{}, user = %User{}) when not is_nil(user) do
    %Auth{user: user, staffer: Staffer.one(user: user, org: org)}
  end

  def get_for_user(%Campaign{org_id: lead_id}, user = %User{}) when not is_nil(user) do
    %Auth{user: user, staffer: Staffer.one(user: user, org: %Org{id: lead_id})}
  end

  def get_for_user(%ActionPage{org_id: owner_id}, user = %User{}) when not is_nil(user) do
    %Auth{user: user, staffer: Staffer.one(user: user, org: %Org{id: owner_id})}
  end

  def get_for_user(_, user = %User{}) when not is_nil(user) do
    %Auth{user: user}
  end
end
