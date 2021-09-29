defmodule Proca.Auth do 
  @defmodule """
  Struct to pass the authorization context.

  - user - refers to authenticated (by email, oauth) person. Has permissions that are instance-global.
  - staffer - refers to org context (has role, set of permissions).
  """
  defstruct user: nil, staffer: nil


end
