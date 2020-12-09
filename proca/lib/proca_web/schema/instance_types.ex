defmodule ProcaWeb.Schema.InstanceTypes do
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers
  alias ProcaWeb.Resolvers.Authorized

  object :instance_queries do

    field :instance, :instance do
      middleware Authorized
    end
  end

  object :instance do
    field :orgs, list_of(non_null(:org))
    field :users, list_of(non_null(:user))
  end

  object :operation do
    field :done, non_null(:boolean)
    field :pending, non_null(:boolean)
  end
end
