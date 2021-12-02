defmodule ProcaWeb.Router do
  @moduledoc """
  Main app router
  """
  use ProcaWeb, :router

  import ProcaWeb.UserAuth
  # import Phoenix.LiveView.Router
  use Plug.ErrorHandler

  def allow_origin, do: Application.get_env( :proca, ProcaWeb.Endpoint)[:allow_origin]

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    # plug :fetch_live_flash # This is for LiveView
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug :put_root_layout, {ProcaWeb.LayoutView, :root}
  end

  pipeline :api do
    # Support current logged in user
    plug :fetch_session
    plug :fetch_current_user

    plug :accepts, ["json"]
    plug CORSPlug
    plug ProcaWeb.Plugs.HeadersPlug, ["referer"]
    plug ProcaWeb.Plugs.BasicAuthPlug
    plug ProcaWeb.Plugs.JwtAuthPlug
  end

  pipeline :api_without_auth do
    plug :accepts, ["json"]
    plug CORSPlug
    plug ProcaWeb.Plugs.HeadersPlug, ["referer"]
  end

  # unused currently, might be useful for /console
  pipeline :auth do
    plug ProcaWeb.Plugs.JwtAuthPlug, query_param: "jwt", enable_session: true
    :require_authenticated_user
  end

  scope "/" do
    pipe_through :browser

    get "/", ProcaWeb.HomepageController, :index
  end

  scope "/link" do 
    pipe_through [:api]

    get "/s/:action_id/:verb/:ref", ProcaWeb.ConfirmController, :supporter
    get "/:verb/:code", ProcaWeb.ConfirmController, :confirm
    #get "/a/:action_id/:ref/:verb/:code", ProcaWeb.ConfirmController, :confirm_code
  end

  scope "/webhook" do
    pipe_through :api_without_auth

    post "/mailjet", ProcaWeb.WebhookController, :mailjet
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

  ## Authentication routes

  scope "/", ProcaWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
    get "/users/log_in", UserSessionController, :new
    post "/users/log_in", UserSessionController, :create
    get "/users/reset_password", UserResetPasswordController, :new
    post "/users/reset_password", UserResetPasswordController, :create
    get "/users/reset_password/:token", UserResetPasswordController, :edit
    put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", ProcaWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end

  scope "/", ProcaWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    get "/users/confirm", UserConfirmationController, :new
    post "/users/confirm", UserConfirmationController, :create
    get "/users/confirm/:token", UserConfirmationController, :confirm
  end
end
