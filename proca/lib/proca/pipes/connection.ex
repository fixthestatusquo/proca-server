defmodule Proca.Pipes.Connection do
  import Logger
  use GenServer
  alias AMQP.Channel
  alias AMQP.Connection
  import AMQP.Basic

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: __MODULE__)
  end

  @impl true
  def init(url) do
    {:ok, %{url: url}, {:continue, :connect}}
  end

  @doc """
  Connect, (todo: reconnect) functionality
  """
  @impl true
  def handle_continue(:connect, st = %{url: url}) do
    case Connection.open(url) do
      {:ok, c} ->
        # Inform us when AMQP connection is down
        Process.monitor(c.pid)

        {
          :noreply,
          %{
            url: url,
            conn: c
          }
        }
      {:error, reason} -> {:stop, reason, st}
    end
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, reason}, %{conn: %{pid: pid}}) do
    Logger.critical([message: "Queue connection down", reason: reason])
    # XXX stop Pipes ?

    # Stop GenServer. Will be restarted by Supervisor.
    # Wait, re-connect?
    {:stop, {:connection_lost, reason}, nil}
  end

  @impl true
  def handle_call(:connection, _from, %{conn: conn} = st) do
    {:reply, conn, st}
  end

  @impl true
  def handle_call(:connection_url, _from, %{url: url} = st) do
    {:reply, url, st}
  end

  # API #
  def connection() do
    GenServer.call(__MODULE__, :connection)
  end

  def connection_url() do
    GenServer.call(__MODULE__, :connection_url)
  end

  def with_chan(f) do
    {:ok, chan} = Channel.open(connection())

    try do
      apply(f, [chan])
    after
      Channel.close(chan)
    end
  end

  @spec publish(String.t(), String.t(), map()) :: :ok | :error
  def publish(exchange, routing_key, data) do
    options = [
      mandatory: true,
      persistent: true
    ]

    with_chan(fn chan ->
      case JSON.encode(data) do
        {:ok, payload} -> publish(chan, exchange, routing_key, payload, options)
        _e -> :error
      end
    end)
  end
end
