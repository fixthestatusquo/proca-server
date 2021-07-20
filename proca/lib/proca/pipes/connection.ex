defmodule Proca.Pipes.Connection do
  import Logger
  use GenServer
  alias AMQP.Channel
  alias AMQP.Connection
  import AMQP.Basic

  @connection_down_reconnect 5
  @econnrefused_reconnect 60 * 5
  @connection_closed_reconnect 30

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: __MODULE__)
  end

  @impl true
  def init(url) do
    {:ok, %{url: url, status: :starting}, {:continue, :connect}}
  end

  @doc """
  Connect, (todo: reconnect) functionality
  """
  @impl true
  def handle_continue(:connect, st) do
    do_connect(st)
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, reason}, st = %{conn: %{pid: pid}}) do
    do_reconnecting(st, @connection_down_reconnect)
  end

  @impl true 
  def handle_info(:reconnect, st = %{status: :reconnecting}) do 
    do_connect(st)
  end

  @impl true 
  def handle_info(:reconnect, st) do 
    # noop, we are not reconnecting
    {:noreply, st}
  end

  @doc """
  Attempts to connect to queue.
  It can succeed and enter status: :connected
  Or it can fail and enter status: :reconnecting
  """
  def do_connect(st = %{url: url}) do
    case Connection.open(url, connect_opts()) do
      {:ok, c} ->
        # Inform us when AMQP connection is down
        Process.monitor(c.pid)

        debug("Queue connection: success")
        Proca.Pipes.Supervisor.handle_connected()

        {
          :noreply,
          %{
            url: url,
            conn: c,
            status: :connected
          }
        }
      
      {:error, :econnrefused} -> 
        do_reconnecting(st, @econnrefused_reconnect)
        # Try reconnecting and run in lowered mode
      
      {:error, {:socket_closed_unexpectedly, _details}} -> 
        do_reconnecting(st, @connection_closed_reconnect)

      {:error, reason} -> 
        error("Queue connection: failed with #{inspect(reason)}")
        {:stop, reason, st}
    end
  end

  @doc """
  Allow setting SSL client connection options
  """
  def connect_opts() do
    opt = Application.get_env(:proca, Proca.Pipes)[:ssl_options]
    need = [:cacertfile, :certfile, :keyfile]
    extra_opt = [verify: :verify_peer, fail_if_no_peer_cert: true]

    if opt != nil and Enum.all?(need, fn k -> Keyword.get(opt, k) != nil end) do 
      [ssl_options: opt ++ extra_opt]
    else
      []
    end
  end


  @doc """
  Reconnecting procedure - shutdown processing and schedule connection attempt `after_seconds`
  """
  def do_reconnecting(%{url: url}, after_seconds) do
    debug("Queue connection: Cannot connect. Running in degraded mode and will retry in #{after_seconds} sec")
    Proca.Pipes.Supervisor.handle_disconnected()
    Process.send_after(self(), :reconnect, after_seconds * 1000)

    {
      :noreply,
      %{
        url: url,
        status: :reconnecting
      }
    }
  end


  @impl true
  def handle_call(:connection, _from, %{conn: conn} = st) do
    {:reply, {:ok, conn}, st}
  end

  @impl true
  def handle_call(:connection, _from, %{status: :reconnecting} = st) do 
    {:reply, {:error, :reconnecting}, st}
  end

  @impl true
  def handle_call(:connection_url, _from, %{url: url} = st) do
    {:reply, url, st}
  end

  # API #
  def connection() do
    GenServer.call(__MODULE__, :connection)
  end

  def is_connected?() do 
    case connection() do
      {:ok, _conn} -> true
      _ -> false 
    end
  end

  def connection_url() do
    GenServer.call(__MODULE__, :connection_url)
  end

  def with_chan(f) do
    case connection() do 
      {:error, _reason} = e -> e

      {:ok, conn} ->
        {:ok, chan} = Channel.open(conn)

        try do
          apply(f, [chan])
        after
          Channel.close(chan)
        end
    end
  end

  @spec publish(String.t(), String.t(), map()) :: :ok | :error
  def publish(exchange, routing_key, data) do
    options = [
      mandatory: true,
      persistent: true
    ]

    r = with_chan(fn chan ->
      case JSON.encode(data) do
        {:ok, payload} -> publish(chan, exchange, routing_key, payload, options)
        _e -> :error
      end
    end)

    case r do 
      {:error, _reason} -> :error
      x -> x
    end
  end
end
