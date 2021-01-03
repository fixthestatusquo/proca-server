defmodule ProcaWeb.Resolvers.User do
  @moduledoc """
  Resolvers for org { } root query
  """
  # import Ecto.Query
  import Ecto.Query
  import Ecto.Changeset

  alias Proca.{ActionPage, Campaign, Action}
  alias Proca.{Org, Staffer, PublicKey}
  alias ProcaWeb.Helper

  alias Proca.Repo
  alias Proca.Staffer.{Permission, Role}

  import Logger


  def current_user(_, _, %{context: %{user: user}}) do
    user = Repo.preload(user, [staffers: :org])

    {:ok,
     %{
       id: user.id,
       email: user.email,
       roles: Enum.map(user.staffers, fn stf ->
         %{
           role: Role.findrole(stf) || "custom",
           org: stf.org
         }
       end)
     }
    }
  end
end
