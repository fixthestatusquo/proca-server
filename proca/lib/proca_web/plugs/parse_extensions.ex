defmodule ProcaWeb.Plugs.ParseExtensions do
  @behaviour Plug

  alias Plug.Conn
  alias ProcaWeb.Plugs.Helper
  import Ecto.Changeset

 #   Absinthe.Plug.put_options(conn, context: context)
  def init(opts \\ []) do
    Keyword.get(opts, :schema)
  end

  def call(conn = %{params: %{"extensions" => ext}}, nil) do
    conn
  end

  def call(conn = %{params: %{"extensions" => ext}}, schema) when is_map(schema) do
    case cast({%{}, schema}, ext, Map.keys(schema)) do
      %{valid?: false} -> Helper.error_halt(conn, 400, :invalid_extensions, "Invalid extensions map")
      %{valid?: true} = ch -> Absinthe.Plug.put_options(conn, context: %{extensions: apply_changes(ch)})
    end
  end


  def call(conn, _k) do
    conn
  end
end
