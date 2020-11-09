defmodule ProcaWeb.Schema.DataTypes do
  @moduledoc """
  Defines custom types used in API, and how to serialize/parse them
  """
  use Absinthe.Schema.Notation
  import Logger

  scalar :datetime do
    parse(fn input ->
      case DateTime.from_iso8601(input.value) do
        {:ok, datetime, _} -> {:ok, datetime}
        _ -> :error
      end
    end)

    serialize(fn datetime ->
      DateTime.from_naive!(datetime, "Etc/UTC")
      |> DateTime.to_iso8601()
    end)
  end

  scalar :date do
    parse(fn input ->
      case Date.from_iso8601(input.value) do
        {:ok, date} -> {:ok, date}
        _ -> :error
      end
    end)

    serialize(fn date ->
      Date.to_iso8601(date)
    end)
  end

  scalar :json do
    parse(fn input ->
      case Jason.decode(input.value) do
        {:ok, object} ->
          {:ok, object}

      x ->
          error [why: "error while decoding json input", input: input.value, msg: x]
          :error
      end
    end)

    serialize(fn object ->
      case Jason.encode(object) do
        {:ok, json} -> json
        _ -> :error
      end
    end)
  end
end
