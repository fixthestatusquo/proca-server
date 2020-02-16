defmodule ProcaWeb.Router do
  use ProcaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ProcaWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  forward "/api", Absinthe.Plug,
    schema: ProcaWeb.Schema

  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: ProcaWeb.Schema, interface: :playground
end
