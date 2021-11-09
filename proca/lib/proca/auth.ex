defmodule Proca.Auth do 
  @defmodule """
  Authorization Context for resolvers.

  We have these authorization scopes:

  - User - Refers to authenticated (by email, oauth) person. Has permissions that are instance-global. The user has an implicit permission to use the API. Admin is a special case of User (has permissions to change server settings, manage all server resoures). 
  - Staffer - Refers to org scope (has role within some org, set of permissions). The org is a namespace for resources: campaigns, action pages, services, staffers. 
  - Coordinator - Refers to campaign scope. This namespace contains a campaign and all its action pages (owned by different orgs).


  The authorization scopes overlap. Eg. Some Action Page can be modified by admin user, by manager staffer, or by a campaign coordinator it belongs to.

  API middleware ProcaWeb.Resolvers.Authorized resolves the current authorization scopes based on query and its arguments.
  """
  defstruct user: nil, staffer: nil


end
