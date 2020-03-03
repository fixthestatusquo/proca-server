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
  end

  scope "/" do
    pipe_through :browser

    pow_routes()
  end

  scope "/", ProcaWeb do
    pipe_through :browser

    live "/", PageController
  end

  scope "/api" do
    pipe_through :api

    forward "/", Absinthe.Plug,
      schema: ProcaWeb.Schema
  end

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: ProcaWeb.Schema, interface: :playground
end
