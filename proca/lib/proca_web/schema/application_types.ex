defmodule ProcaWeb.Schema.ApplicationTypes do
  @moduledoc """
  API for general application info
  """

  use Absinthe.Schema.Notation

  alias ProcaWeb.Resolvers
  import ProcaWeb.Resolvers.AuthNotation

  object :application_queries do
    @desc "Get application info"
    field :application, :application do
      determine_auth(for: :result)
      allow([:instance_owner])
      resolve(&Resolvers.Application.info/3)
    end
  end

  object :application do
    field :name, :string
    field :version, :string
  end
end
