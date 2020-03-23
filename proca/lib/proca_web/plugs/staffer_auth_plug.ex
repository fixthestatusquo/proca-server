defmodule ProcaWeb.Plugs.StafferAuthPlug do
  alias ProcaWeb.Router.Helpers, as: Routes
  alias Plug.Conn
  alias Pow.Config
  alias Pow.Plug

  @doc false
  @spec init(Config.t()) :: atom()
  def init(config) do
    Config.get(config, :session_key) || raise_no_error_handler()
  end

  @doc "
This plug will check if the Staffer is stored in the session.
If there is a staffer in session, pass.
If not, it will try to find one Staffer for current user.
If staffer is not found redirect to / (:index)
"
  @spec call(Conn.t(), atom()) :: Conn.t()
  def call(conn, session_key) do
    user = Plug.current_user(conn)

    case Conn.get_session(conn, session_key) do
      cur_staffer when is_nil(cur_staffer) ->
        case Proca.Staffer.for_user(user) do
          none when is_nil(none) ->
            not_a_staffer(conn)
          staffer ->
            update_staffer_last_signin(staffer)
            conn
            |> Conn.put_session(session_key, staffer)
        end
      _staffer -> conn
    end
  end

  defp not_a_staffer(conn) do
    conn
    |> Phoenix.Controller.put_flash(:error, "You are not a staffer of this organisation.")
    |> Phoenix.Controller.redirect(to: Routes.page_path(conn, :index)) 
  end


  defp not_signed_in(conn) do
    conn
    |> Phoenix.Controller.put_flash(:error, "You are not signed in.")
    |> Phoenix.Controller.redirect(to: Routes.pow_session_path(conn, :new)) 
  end

  @spec raise_no_error_handler :: no_return
  defp raise_no_error_handler do
    Config.raise_error("No :session_key configuration option provided. session_key must specify which session key witll hold Staffer record. It's required to set this when using #{inspect __MODULE__}.")
  end

  def switch_to_org(conn, session_key, org_name) do
    case Plug.current_user(conn) do
      user when is_nil(user) ->
        not_signed_in(conn)
      user ->
        case Proca.Staffer.for_user_in_org(user, org_name) do
          none when is_nil(none) ->
            not_a_staffer(conn)
          staffer ->
            update_staffer_last_signin(staffer)
            conn
            |> Conn.put_session(session_key, staffer)
        end
    end
  end

  def update_staffer_last_signin(staffer) do
    Proca.Staffer.changeset(staffer, %{last_signin_at: DateTime.utc_now()})
    |> Proca.Repo.update()
  end
end
