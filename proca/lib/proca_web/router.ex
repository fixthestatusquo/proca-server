defmodule ProcaWeb.Router do
  use ProcaWeb, :router
  import Phoenix.LiveView.Router
  use Pow.Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: "*"
    plug ProcaWeb.Plugs.ApiAuthPlug
  end

  pipeline :auth do
    plug Pow.Plug.RequireAuthenticated, error_handler: Pow.Phoenix.PlugErrorHandler
  end

  pipeline :org do
    plug ProcaWeb.Plugs.StafferAuthPlug, session_key: :staffer
  end

  scope "/" do
    pipe_through :browser

    # For keeping the session from expiring when user is just using websocket (in liveview)
    get "/keep-alive", ProcaWeb.HelperController, :noop

    get "/", ProcaWeb.PageController, :index
    pow_routes()
  end

  scope "/dash", ProcaWeb do
    pipe_through [:browser, :auth, :org]

    live "/orgs", OrgsController
    live "/settings/encryption", EncryptionController
    live "/settings/team", TeamController
    live "/", DashController
  end

  scope "/api" do
    pipe_through :api

    forward "/", Absinthe.Plug,
      schema: ProcaWeb.Schema
  end

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: ProcaWeb.Schema, interface: :playground, default_url: "/api"
end
