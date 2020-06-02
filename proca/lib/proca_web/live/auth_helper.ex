defmodule ProcaWeb.Live.AuthHelper do
  @moduledoc """
    Will assign the user and staffer from the session token, to the live view socket.

    defmodule AppNameWeb.SomeViewLive do
        use PhoenixLiveView
        use AppNameWeb.LiveViewPowHelper

        def mount(session, socket) do
          socket = mount_user(socket, session)

          # ...
        end
    end

  """

  alias Proca.Users.User
  alias Proca.Staffer
  alias Phoenix.LiveView.Socket
  alias Pow.Store.CredentialsCache

  require Logger

  defmacro __using__(opts) do
    # Customise this for your app
    # You'll also need to replace the references to "app_name_auth"
    renewal_config      = [renew_session: true, interval: :timer.seconds(5)]
    pow_config  = [otp_app: opts[:otp_app]]

    quote do
      
      @pow_config unquote(Macro.escape(pow_config)) ++ [module: __MODULE__]
      @renewal_config unquote(Macro.escape(renewal_config)) ++ [module: __MODULE__]

      def mount_user(socket, session), do: unquote(__MODULE__).mount_user(socket, self(), session, @pow_config, @renewal_config)
      def handle_info({:renew_pow_session, session}, socket), do: unquote(__MODULE__).handle_renew_pow_session(socket, self(), session, @pow_config, @renewal_config)
    end
  end

  @doc """
  Retrieves the currently-logged-in user from the Pow credentials cache.
  """
  def get_user(socket, session, pow_config) do
    with {:ok, token} <- verify_token(socket, session, pow_config),
         {user, _metadata} = pow_credential <- CredentialsCache.get(pow_config, token) do
          user
    else
      _any -> nil
    end
  end

  # Convienience to assign straight into the socket
  def mount_user(socket, pid, session, pow_config, renewal_config) do
    case get_user(socket, session, pow_config) do
      %User{} = user ->
        maybe_init_session_renewal(
          socket,
          pid,
          session,
          renewal_config |> Keyword.get(:renew_session),
          renewal_config |> Keyword.get(:interval)
        )
        assign_current_user(socket, user, session)
      _ -> socket
    end
  end
  def maybe_assign_current_user(_, _, _), do: nil

  # assigns the current_user to the socket with the key current_user
  def assign_current_user(socket, %{id: user_id} = user, session) do
    staffer = case Map.get(session, "staffer", nil) do
                staffer = %Staffer{user_id: ^user_id} -> staffer
                _ -> nil
              end
    socket
    |> Phoenix.LiveView.assign(user: user)
    |> Phoenix.LiveView.assign(staffer: staffer)
  end

  # Session Renewal Logic
  def maybe_init_session_renewal(_, _, _, false, _), do: nil
  def maybe_init_session_renewal(socket, pid, session, true, interval) do
    if Phoenix.LiveView.connected?(socket) do
      Process.send_after(pid, {:renew_pow_session, session}, interval)
    end
  end

  def handle_renew_pow_session(socket, pid, session, pow_config, renewal_config) do
    with  {:ok, token} <- verify_token(socket, session, pow_config),
          {_user, _metadata} = pow_credential <- CredentialsCache.get(pow_config, token),
          :ok <- update_session_ttl(pow_config, token, pow_credential)  do

        # Successfully updates so queue up another renewal
        Process.send_after(pid, {:renew_pow_session, session}, renewal_config |> Keyword.get(:interval))
    else
      _any -> nil
    end

    {:noreply, socket}
  end

  # Verifies the session token
  defp verify_token(socket, %{"proca_auth" => signed_token}, pow_config) do
    conn = struct!(Plug.Conn, secret_key_base: socket.endpoint.config(:secret_key_base))
    salt = Atom.to_string(Pow.Plug.Session)
    Pow.Plug.verify_token(conn, salt, signed_token, pow_config)
  end
  defp verify_token(_, _, _), do: nil

  # Updates the TTL on POW credential in the cache
  def update_session_ttl(pow_config, session_token, {%User{} = user, _metadata} = pow_credential) do

    sessions = CredentialsCache.sessions(pow_config, user)

    # Do we have an available session which matches the fingerprint?
    # If yes, lets update it's TTL by passing the previously fetched credential
    if sessions |> Enum.find(& &1 == session_token) do
      CredentialsCache.put(pow_config, session_token, pow_credential)
    end
  end

end
