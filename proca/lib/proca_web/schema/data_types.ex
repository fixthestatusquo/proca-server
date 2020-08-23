defmodule ProcaWeb.Schema.DataTypes do
  use Absinthe.Schema.Notation
  alias ProcaWeb.Resolvers


  scalar :datetime do
    parse fn input ->
      case DateTime.from_iso8601(input.value) do
        {:ok, datetime, _} -> {:ok, datetime}
        _ -> :error
      end
    end

    serialize fn datetime ->
      DateTime.from_naive!(datetime, "Etc/UTC")
      |> DateTime.to_iso8601()
    end
  end
end
