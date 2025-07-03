defmodule ProcaWeb.Schema.InstanceTypes do
  use Absinthe.Schema.Notation
  import ProcaWeb.Resolvers.AuthNotation

  # XXX unused, remove?

  object :instance_queries do
    field :instance, non_null(:instance) do
      allow([:instance_owner])
    end
  end

  object :instance do
    field :orgs, non_null(list_of(non_null(:org)))
    field :users, non_null(list_of(non_null(:user)))
  end

  object :operation do
    field :done, non_null(:boolean)
    field :pending, non_null(:boolean)
  end
end
