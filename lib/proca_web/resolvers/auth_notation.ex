defmodule ProcaWeb.Resolvers.AuthNotation do
  @moduledoc """
  Provides macros to handle auth flow in schema files.


  For queries:

  - `load :campaign, by: [:id]` - fetch a record by primary or secondary identifier


  - `determine_auth for: result` - use after a resolution. Provides a relevant
    Auth context for interfaces to be resolved (public vs private)

  For mutatuins an queries

  - `allow` - allow list of permissions to run that mutation or receive that value


  """
  import Absinthe.Schema.Notation, only: [middleware: 2]

  @doc """
  determine_auth for: :result
  """
  defmacro determine_auth(opts) do
    quote do
      middleware(ProcaWeb.Resolvers.AuthResolver, unquote(opts))
    end
  end

  @doc """
  load :campaign, by: [:id, :external_id, :name]
  """
  defmacro load(type, by_fields) do
    quote do
      middleware(ProcaWeb.Resolvers.Loader, [unquote(type) | unquote(by_fields)])
    end
  end

  def load_assoc_resolver(
        parent,
        _,
        _resol = %{
          definition: %{
            schema_node: %{
              identifier: field
            }
          }
        }
      ) do
    alias Proca.Repo

    {
      :ok,
      Repo.preload(parent, [field])
      |> Map.get(field)
    }
  end

  defmacro load_assoc() do
    quote do
      resolve(&ProcaWeb.Resolvers.AuthNotation.load_assoc_resolver/3)
    end
  end

  @doc """
  allow [:manage_orgs, :perm2, :perm3]
  """
  defmacro allow(perms) do
    quote do
      middleware(ProcaWeb.Resolvers.AuthAllow, unquote(perms))
    end
  end
end
