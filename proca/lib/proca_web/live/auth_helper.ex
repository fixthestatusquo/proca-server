defmodule ProcaWeb.Live.AuthHelper do
  @moduledoc """
  Handle pow user in LiveView.

  Will assign the current user and periodically check that the session is still
  active. `session_expired/1` will be called when session expires.

  Configuration options:

  * `:otp_app` - the app name
  * `:interval` - how often the session has to be checked, defaults 60s

  defmodule LendingWeb.SomeViewLive do
  use PhoenixLiveView
  use LendingWeb.Live.AuthHelper, otp_app: :otp_app

  def mount(session, socket) do
  socket = mount_user(socket, session)

  # ...
  end

  def session_expired(socket) do
  # handle session expiration

  {:noreply, socket}
  end
  end
  """
  require Logger

  import Phoenix.LiveView, only: [assign: 3]

  defmacro __using__(opts) do
    config              = [otp_app: opts[:otp_app]]
    session_id_key      = Pow.Plug.prepend_with_namespace(config, "auth")
    auth_check_interval = Keyword.get(opts, :auth_check_interval, :timer.seconds(1))

    config = [
      session_id_key: session_id_key,
      auth_check_interval: auth_check_interval,
    ]

    quote do
      @config unquote(Macro.escape(config)) ++ [
        live_view_module: __MODULE__,
      ]

      def mount_user(socket, session),
          do: unquote(__MODULE__).mount_user(socket, self(), session, @config)

      def handle_info(:pow_auth_ttl, socket),
          do: unquote(__MODULE__).handle_auth_ttl(socket, self(), @config)
    end
  end

  def mount_user(socket, pid, session, config) do
    session_id  = Map.fetch!(session, config[:session_id_key])

    IO.inspect session

    case credentials_by_session_id(session_id) do
      {user, meta} ->
        socket = socket
        |> assign(:credentials_meta, meta)
        |> assign(:user, user)
        |> assign(:staffer, Map.get(session, "staffer"))

        if Phoenix.LiveView.connected?(socket) do
          init_auth_check(pid)
        end

        socket

      _everything_else ->
        socket
    end
  end

  defp init_auth_check(pid) do
    Process.send_after(pid, :pow_auth_ttl, 0)
  end

  def handle_auth_ttl(socket, pid, config) do
    auth_check_interval = Pow.Config.get(config, :auth_check_interval)

    case session_id_by_credentials(socket.assigns[:user], socket.assigns[:credentials_meta]) do
      x when is_nil(x) ->
        # Logger.info("[#{__MODULE__}] User session no longer active")

        {
          :noreply,
          socket
          |> assign(:credentials_meta, nil)
          |> assign(:user, nil)
          |> assign(:staffer, nil)
        }

      _session_id ->
        # Logger.info("[#{__MODULE__}] User session still active")

        Process.send_after(pid, :pow_auth_ttl, auth_check_interval)

        {:noreply, socket}
    end
  end

  defp session_id_by_credentials(nil, nil), do: nil
  defp session_id_by_credentials(user, meta) do
    all_user_session_ids = Pow.Store.CredentialsCache.sessions(
      [backend: Pow.Store.Backend.EtsCache],
      user
    )

    all_user_session_ids |> Enum.find(fn session_id ->
      {_, session_meta} = credentials_by_session_id(session_id)

      session_meta[:fingerprint] == meta[:fingerprint]
    end)
  end

  defp credentials_by_session_id(session_id) do
    Pow.Store.CredentialsCache.get(
      [backend: Pow.Store.Backend.EtsCache],
      session_id
    )
  end
end
