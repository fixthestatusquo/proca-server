defmodule ProcaWeb.EciRouter do
  use ProcaWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: "*"
  end

  scope "/api" do
    pipe_through :api

    forward "/", Absinthe.Plug,
      schema: ProcaWeb.Schema.EciSchema
  end
  
  forward "/graphiql", Absinthe.Plug.GraphiQL,
    schema: ProcaWeb.Schema.EciSchema,
    interface: :playground,
    default_url: "/api"
end
