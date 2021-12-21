defmodule ProcaWeb.Resolvers.ChangeAuth do 
  @behaviour Absinthe.Middleware
  alias Proca.Auth

  @doc """
  Second argument is a tuple of
  - auth
  - value :: {:ok, return} | {:error, [term]}
  """
  def call(resolution, {%Auth{} = auth, value}) do 
    %{
      resolution
      | context:
          resolution.context
          |> Map.put(:staffer, auth.staffer) # XXX DEPRECATE -> use auth.staffer
          |> Map.put(:auth, auth)
    }
    |> Absinthe.Resolution.put_result(value)
  end

  def return(%Auth{} = auth, value) do 
    {:middleware, __MODULE__, {auth, value}}
  end

end
