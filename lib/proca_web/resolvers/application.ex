defmodule ProcaWeb.Resolvers.Application do
  @moduledoc """
  Resolvers for application queries
  """

  require Logger

  def info(_, _, _) do
    spec = %{
      name: Application.spec(:proca, :description),
      version: Application.spec(:proca, :vsn),
      log_level: Logger.level()
    }

    {:ok, spec}
  end
end
