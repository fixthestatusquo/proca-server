defmodule ProcaWeb.EciRouter do
  @moduledoc """
  Alternative router used in ECI build. Minimal version of ProcaWeb.Router
  """
  use ProcaWeb, :router
  use Plug.ErrorHandler
  use Sentry.Plug

  pipeline :api do
    plug :accepts, ["json"]
    plug CORSPlug, origin: "*"
    plug ProcaWeb.Plugs.BlockIntrospectionPlug
    plug ProcaWeb.Plugs.ParseExtensions, schema: %{captcha: :string}
  end

  scope "/api" do
    pipe_through :api

    forward "/", Absinthe.Plug, schema: ProcaWeb.Schema.EciSchema
  end

  # forward "/graphiql", Absinthe.Plug.GraphiQL,
  #   schema: ProcaWeb.Schema.EciSchema,
  #   interface: :playground,
  #   default_url: "/api"
end
