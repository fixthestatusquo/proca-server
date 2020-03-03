defmodule ProcaWeb.Plugs.StafferAuthPlug do
  alias ProcaWeb.Router.Helpers, as: Routes
  alias Plug.Conn
  alias Pow.Config
  alias Pow.Plug

  @doc false
  @spec init(Config.t()) :: charlist()
  def init(config) do
    Config.get(config, :org_param) || raise_no_error_handler()
  end

  @doc false
  @spec call(Conn.t(), charlist()) :: Conn.t()
  def call(%{ params: params } = conn, org_param) do
    org_name = Map.get(params, org_param)
    user = Plug.current_user(conn)
    IO.inspect "org is #{org_name}"
    case Proca.Staffer.for_user_in_org(user, org_name) do
      none when is_nil(none) ->
        IO.puts "NOT A STAFFER"
        not_a_staffer(conn, org_name)
      staffer ->
        IO.puts "OK GOT STAFFER #{staffer.id}"
        Conn.put_session(conn, :staffer, staffer)
    end
  end

  defp not_a_staffer(conn, org_name) do
    conn
    |> Phoenix.Controller.put_flash(:error, "You are not a staffer of #{org_name}")
    |> Phoenix.Controller.redirect(to: Routes.page_path(conn, :index)) 
  end

  @spec raise_no_error_handler :: no_return
  defp raise_no_error_handler do
    Config.raise_error("No :org_param configuration option provided. It's required to set this when using #{inspect __MODULE__}.")
  end
end
