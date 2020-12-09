defmodule ProcaWeb.Schema.DataTypes do
  @moduledoc """
  Defines custom types used in API, and how to serialize/parse them
  """
  use Absinthe.Schema.Notation
  import Logger

  scalar :date_time do
    parse(fn %{value: value} ->
      case DateTime.from_iso8601(value) do
        {:ok, datetime, _} -> {:ok, datetime}
        _ -> :error
      end
      _ -> :error
    end)

    serialize(fn datetime ->
      DateTime.from_naive!(datetime, "Etc/UTC")
      |> DateTime.to_iso8601()
    end)
  end

  scalar :date do
    parse(fn %{value: value} ->
      case Date.from_iso8601(value) do
        {:ok, date} -> {:ok, date}
        _ -> :error
      end
      _ -> :error
    end)

    serialize(fn date ->
      Date.to_iso8601(date)
    end)
  end

  scalar :json do
    parse(fn %{value: value} ->
      case Jason.decode(value) do
        {:ok, object} ->
          {:ok, object}

      x ->
          error [why: "error while decoding json input", input: value, msg: x]
          :error
      end
      _ -> :error
    end)

    serialize(fn object ->
      case Jason.encode(object) do
        {:ok, json} -> json
        _ -> :error
      end
    end)
  end

  enum :status do
    value :success, description: "Operation completed succesfully"
    value :confirming, description: "Operation awaiting confirmation"
  end

  object :delete_result do
    field :success, non_null(:boolean)
  end
end
