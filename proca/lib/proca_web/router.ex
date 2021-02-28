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

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: "*"
    plug ProcaWeb.Plugs.BasicAuthPlug
    plug ProcaWeb.Plugs.JwtAuthPlug
  end

  pipeline :auth do
    plug ProcaWeb.Plugs.JwtAuthPlug, query_param: "jwt", enable_session: true
    plug Pow.Plug.RequireAuthenticated, error_handler: Pow.Phoenix.PlugErrorHandler
  end

  scope "/" do
    pipe_through :browser

    # For keeping the session from expiring when user is just using websocket (in liveview)
    get "/keep-alive", ProcaWeb.HelperController, :noop

    get "/", ProcaWeb.PageController, :index
    pow_routes()
  end

  scope "/dash", ProcaWeb do
    pipe_through [:browser, :auth]

    live "/orgs", OrgsController
    live "/campaigns", CampaignsController
    live "/settings/encryption", EncryptionController
    live "/settings/team", TeamController
    live "/", DashController
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
