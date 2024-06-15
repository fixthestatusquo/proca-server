defmodule ProcaWeb.Resolvers.Application do
  @moduledoc """
  Resolvers for application queries
  """

  def info(_, _, _) do
    spec = %{
      name: Application.spec(:proca, :description),
      version: Application.spec(:proca, :vsn)
    }

    {:ok, spec}
  end
end
