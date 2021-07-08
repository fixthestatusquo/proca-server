defmodule ProcaWeb.Router do
  @moduledoc """
  Main app router
  """
  use ProcaWeb, :router
  import Phoenix.LiveView.Router
  use Pow.Phoenix.Router
  use Plug.ErrorHandler

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {ProcaWeb.LayoutView, :root}
  end

  allowed_origins = Application.get_env(:proca, Proca)[:allowed_origins]

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: allowed_origins
    plug ProcaWeb.Plugs.HeadersPlug, ["referer"]
    plug ProcaWeb.Plugs.BasicAuthPlug
    plug ProcaWeb.Plugs.JwtAuthPlug
  end

  pipeline :auth do
    plug ProcaWeb.Plugs.JwtAuthPlug, query_param: "jwt", enable_session: true
    plug Pow.Plug.RequireAuthenticated, error_handler: Pow.Phoenix.PlugErrorHandler
  end

  scope "/" do
    pipe_through :browser

    get "/", ProcaWeb.PageController, :index
    pow_routes()
  end

  scope "/link" do
    pipe_through :api

    get "/s/:action_id/:verb/:ref", ProcaWeb.ConfirmController, :supporter
    get "/:verb/:code", ProcaWeb.ConfirmController, :confirm
    # get "/a/:action_id/:ref/:verb/:code", ProcaWeb.ConfirmController, :confirm_code
  end

  scope "/api" do
    pipe_through :api

    forward "/", Absinthe.Plug,
      schema: ProcaWeb.Schema,
      socket: ProcaWeb.UserSocket
  end

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: ProcaWeb.Schema,
    socket: ProcaWeb.UserSocket,
    interface: :playground,
    default_url: "/api"
end
