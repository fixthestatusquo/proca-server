defmodule ProcaWeb.Plugs.BlockIntrospectionPlug do
  alias ProcaWeb.Plugs.Helper
  @behaviour Plug

  def init(opts), do: opts

  def call(conn = %{params: %{"query" => query}}, _opts) do
    if String.contains?(query, "__schema") do
      Helper.error_halt(conn, 401, "unauthorized", "Introspection not authorized")
    else
      conn
    end
  end

  def call(conn, _opts) do
    conn
  end

end
