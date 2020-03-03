defmodule ProcaWeb.Helper do
  def format_errors(changeset) do
    changeset.errors
    |> Enum.map(fn {field, {msg, _}} ->
      %{ message: "#{field}: #{msg}" }
    end)
  end
end
