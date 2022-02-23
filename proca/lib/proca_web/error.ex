defmodule ProcaWeb.Error do
  @moduledoc """
  Error struct to be used universally in the resolver codebase - translated to the respective (GraphQL, REST) error formats.
  """
  defstruct [:code, :message, status_code: 200, context: []]
end
