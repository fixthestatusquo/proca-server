defmodule ProcaWeb.Resolvers.AuthResolver do
  @moduledoc """
  Given authenticated user, looks up Proca.Auth struct that matches contextually
  to resolution result or context. Has two modes:

  - when option is `[from: result]`, it will take a record returned as {:ok, record} and find relevant user access
  - when option is `[from  :org | :campaign | :action_page]` it will find auth for :org, :campaign, :action_page from context
  """
  @behaviour Absinthe.Middleware
  alias Proca.Auth
  alias Absinthe.Resolution

  @impl true
  def call(resolution, for: :result) do
    resolution
    |> get_auth_for_value(resolution.value)
  end

  @impl true
  def call(resolution, for: type) when type in [:org, :campaign, :action_page] do
    resolution
    |> get_auth_for_value(resolution.context[type])
  end

  defp get_auth_for_value(
         resolution = %Resolution{context: %{user: user}},
         record
       )
       when is_struct(record) do
    auth = Auth.get_for_user(record, user)
    %{resolution | context: Map.put(resolution.context, :auth, auth)}
  end

  defp get_auth_for_value(resolution, _record), do: resolution
end
