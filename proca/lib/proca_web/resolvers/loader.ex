defmodule ProcaWeb.Resolvers.Loader do
  @moduledoc """
  middleware Loader, :campaign, by: [name: :campaign_name, :id]
  """
  @behaviour Absinthe.Middleware
  alias Absinthe.Resolution
  alias ProcaWeb.Error

  @impl true
  def call(r = %Resolution{state: :resolved}, _), do: r

  @impl true
  def call(resolution, [type | kw]) do
    {by_fields, other_criteria} = Keyword.pop(kw, :by, [:id])

    by_args = by_fields
    |> Enum.map(fn
      f when is_atom(f) -> {f, f}
      {f, a} when is_atom(f) and is_atom(a) -> {a, f}
    end)
    |> Enum.into(%{})

    given_ids = Map.take(resolution.arguments, Map.keys(by_args))

    if map_size(given_ids) == 1 do
      {arg, val} = Enum.at(given_ids, 0)
      field = by_args[arg]
      case get(type, field, val, other_criteria) do
        nil -> Resolution.put_result(resolution,
                    {:error, %Error{
                        code: "not_found",
                        message: "Entity not found"
                     }})
        record -> %{resolution | context: Map.put(resolution.context, type, record)}
      end
    else
      Resolution.put_result(resolution,
        {:error, %Error{
            code: "bad_arg",
            message: "Provide exactly one identifier argument"}})
      |> IO.inspect(label: "why?")

    end
  end

  defp get(type, field, val, criteria) do
    schema(type).one([{field, val}] ++ criteria)
  end

  defp schema(:campaign), do: Proca.Campaign
  defp schema(:org), do: Proca.Org
  defp schema(:action_page), do: Proca.ActionPage
 end
