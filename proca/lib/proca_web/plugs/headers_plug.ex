defmodule ProcaWeb.Plugs.HeadersPlug do
  @moduledoc """
  A plug that passes headers from request to Absinthe context (into `:headers` map).
  """
  @behaviour Plug

  def init(headers) when is_list(headers), do: headers

  def call(conn, headers) do
    conn
    |> add_location(headers)
  end

  def add_location(conn, headers) do
    for h <- headers, reduce: conn do
      c ->
        case List.keyfind(conn.req_headers, h, 0) do
          {h, val} ->
            c |> Absinthe.Plug.assign_context(%{headers: %{h => val}})

          nil ->
            c
        end
    end
  end
end
