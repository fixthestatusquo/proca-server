defmodule ProcaWeb.Plugs.HeadersPlug do
  @moduledoc """
  A plug that passes headers from request to Absinthe context (into `:headers` map).
  """
  @behaviour Plug

  def init(headers) when is_list(headers), do: headers

  def call(conn, headers) do
    add_location(conn, headers)
  end

  def add_location(conn, headers) do
    # assign once: Absinthe.Plug.assign_context merges shallowly, so a second
    # call would replace :headers instead of adding to it
    Absinthe.Plug.assign_context(conn, %{headers: Map.take(Map.new(conn.req_headers), headers)})
  end
end
