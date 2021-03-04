defmodule ProcaWeb.Plugs.HeadersPlug do
  @moduledoc """
  A plug that reads JWT from Authorization header and authenticates the user
  """
  @behaviour Plug

  alias Plug.Conn
  alias Pow.Plug
  import ProcaWeb.Plugs.Helper

  #   Absinthe.Plug.put_options(conn, context: context)
  def init(headers) when is_list(headers), do: headers

  def call(conn, headers) do
    conn
    |> add_location(headers)
  end

  def add_location(conn, headers) do 
    for h <- headers, reduce: conn do 
      c -> case List.keyfind(conn.req_headers, h, 0) do
        {h, val} ->
          c |> Absinthe.Plug.put_options(%{context: %{ headers: %{ h => val}}})
        nil -> c
      end
    end
  end
end
