defmodule Proca.Server.Plumbing do
  use GenServer
  alias AMQP.{Channel, Queue, Exchange}
  import AMQP.Basic
  alias Proca.{Org}

  @moduledoc """
  Plumbing server is responsible for setting up the signature processing in Proca.

  # How does this work?

  Proca uses RabbitMQ queues and Broadway to process signatures, while updating
  the record to mark that it was processed in each stage.

  ## Stages:

  `Proca.Supporter` is always connected to one or more `Proca.Action`s, but in
  case of confirming we first confirm the supporter, and then we confirm action.

  1. Confirmation stage. Entities are supposed only to be confirmed by one
  mechanism, so they land in one queue (because of routing key design)

     a. Supporter - confirm if needed(double-opt-in)
     b. Action - confirm if needed(moderation of types)

  2. Delivery stage. Entities are processed in parallel by many delivery
  mechanisms, and are copied to many queues as needed (routing keys with
  wildcards)

     a. Action only, but with supporter info.

  ## Routing:
  The routing keys have such structure in both confirm and deliver exchange:

  ```
  org . custom-or-system . type
         ^                   ^
         |                   `-- supporter or action
         --- system if proca processes
              custom if some other system reads from custom queue and GETs callbacks

  ```
  ## Data:

  1. Supporter
    - Contains campaign and action_page data/reference
    - Supporter (encrypted, with personalisation data)
  2. Action
    - Contains campaign and action_page data/reference
    - Action with type, fields

  ## Queues:

  ```
               ___ *.system.supporter        -> system.email.confirm (double opt in)
              /
  confirm ---*---- ORG_NAME.custom.supporter -> ORG_NAME.confirm
              \\___ ORG_NAME.custom.action    -> ORG_NAME.moderate


               ___ *.system.* -> system.email.thankyou
              /
  deliver ---*---- ORG_NAME.*.* -> ORG_NAME.crm
              \\____ ORG1,ORG2,ORG3.system.* -> system.sqs
  ```

  Some queues will by read by external consumer, actually all the ORG* queues.
  They need full data. OTOH, system queues will be able to deal with a simple
  set of action_ids etc, with AP id and Org id to help batching these messages.

  XXX maybe system.email.confirm can be merged with system.email.thankyou ?

  ## Retry queues:

  We use an exchange loop for implementing retries:
  ```
  [queue_name] with dlx set to -> (system.fail rk=queue_name)

  (system.fail) - # -> [system.retry ttl=30sec] with dlx set to -> (system.retry)
  ````

  """
  @impl true
  def init(url) do
    {:ok, %{conn: nil, url: url}, {:continue, :connect}}
  end

  def start_link(url) do
    GenServer.start_link(__MODULE__, url, name: __MODULE__)
  end

  @impl true
  def handle_continue(:connect, st) do
    case AMQP.Connection.open(st.url) do
      {:ok, c} ->
        # Inform us when AMQP connection is down
        Process.monitor(c.pid)

        # Sets up top level proca exchanges
        setup_exchanges(c)
        setup_global_queues(c)
        setup_org_queues(c)

        {
          :noreply,
          %{st | conn: c}
        }
      {:error, reason} -> {:stop, reason, st}
    end
  end

  @impl true
  def handle_info({:DOWN, _, :process, pid, reason}, %{conn: %{pid: pid}}) do
    # Stop GenServer. Will be restarted by Supervisor.
    {:stop, {:connection_lost, reason}, nil}
  end

  # non-public API

  @impl true
  def handle_call(:state, _from, st) do
    {:reply, st, st}
  end

  @impl true
  def handle_call(:connection, _from, %{conn: conn} = st) do
    {:reply, conn, st}
  end

  @impl true
  def handle_call(:connection_url, _from, %{url: url} = st) do
    {:reply, url, st}
  end

  @impl true
  def handle_cast(:setup, %{conn: c} = s) do
    setup_exchanges(c)
    setup_global_queues(c)
    setup_org_queues(c)
    {:noreply, s}
  end

  def setup() do
    GenServer.cast(__MODULE__, :setup)
  end

  def connection() do
    GenServer.call(__MODULE__, :connection)
  end

  def connection_url() do
    GenServer.call(__MODULE__, :connection_url)
  end

  @doc """
  Create exchanges for two stages of processing: confirm queue where
  data is confirmed, and then delivery queue where data can be processed
  further.
  """

  def setup_exchanges(connection) do
    {:ok, chan} = Channel.open(connection)

    try do
      :ok = Exchange.declare(chan, "confirm", :topic, durable: true)
      :ok = Exchange.declare(chan, "deliver", :topic, durable: true)
      :ok = Exchange.declare(chan, "system.fail", :topic, durable: true)
      :ok = Exchange.declare(chan, "system.retry", :topic, durable: true)
    rescue
      _ -> Channel.close(chan)
    end
  end

  defp dlx(exchange_name) do
    {"x-dead-letter-exchange", :longstr, exchange_name}
  end

  defp dlk(routing_key) do
    {"x-dead-letter-routing-key", :longstr, routing_key}
  end

  defp ttl(sec) do
    {"x-message-ttl", :long, round(sec * 1000)}
  end

  def setup_global_queues(connection) do
    queues = [
      {"system.fail", "#", "system.failed", arguments: [dlx("system.retry"), ttl(30)]},
      {"confirm", "*.system.supporter", "system.email.confirm", retry: true},
      {"deliver", "*.system.*", "system.email.thankyou", retry: true},
      {"system.sqs"}
    ]

    setup_queues(connection, queues)
  end

  def setup_org_queues(connection) do
    Proca.Repo.all(Org)
    |> Enum.each(fn org -> setup_org_queues(connection, org) end)
  end

  @doc """
  Org queues:
  - standard
  - specific: crm
  """
  def setup_org_queues(connection, %Org{name: org_name, system_sqs_deliver: enable_sqs}) do
    queues = [
      {"confirm", "#{org_name}.custom.supporter", "custom.#{org_name}.confirm"},
      {"confirm", "#{org_name}.custom.action", "custom.#{org_name}.moderate"},
      {"deliver", "#{org_name}.custom.action", "custom.#{org_name}.deliver"},
      {"deliver", "#{org_name}.system.action", "system.sqs", bind: enable_sqs}
    ]

    setup_queues(connection, queues)
  end

  ## XXX add drop_org_queues
  ## XXX This is unused and maybe using setup_queues would be better instead
  def create_crm_queue(connection, org) do
    create_org_queue(connection, org, {"deliver", "*.*", "crm"})
  end

  ## XXX This is unused and maybe using setup_queues would be better instead
  def drop_crm_queue(connection, org) do
    drop_org_queue(connection, org, {"deliver", "*.*", "crm"})
  end

  ## XXX This is unused and maybe using setup_queues would be better instead
  def create_org_queue(connection, %Org{name: org_name}, {ex, rk, qn}) do
    setup_queues(connection, [{ex, "#{org_name}.#{rk}", "custom.#{org_name}.#{qn}"}])
  end

  # what happens on error? who retries? nmaybe this should be escalated to ui
  ## XXX This is unused and maybe using setup_queues would be better instead
  def drop_org_queue(connection, %Org{name: org_name}, {_ex, _rk, qn}) do
    with_chan(connection, fn chan ->
      Queue.delete(chan, "custom.#{org_name}.#{qn}", if_unused: true, if_empty: true)
    end)
  end

  @spec push(String.t(), String.t(), map()) :: :ok | :error
  def push(exchange, routing_key, data) do
    options = [
      mandatory: true,
      persistent: true
    ]

    with_chan(connection(), fn chan ->
      case JSON.encode(data) do
        {:ok, payload} -> publish(chan, exchange, routing_key, payload, options)
        _e -> :error
      end
    end)
  end

  ############################################
  # Helpers
  def setup_queues(connection, queue_defs) do
    with_chan(connection, fn chan ->
      queue_defs
      |> Enum.each(&setup_queue(chan, &1))
    end)
  end

  def setup_queue(chan, {qu})
  when is_bitstring(qu) do
    setup_queue(chan, {"", "", qu, bind: :skip})
  end

  def setup_queue(chan, {qu, opts})
  when is_bitstring(qu)
  and is_list(opts) do
    setup_queue(chan, {"", "", qu, opts})
  end

  def setup_queue(chan, {ex, rk, qu})
  when is_bitstring(ex)
  and is_bitstring(rk)
  and is_bitstring(qu) do
    setup_queue(chan, {ex, rk, qu, []})
  end

  def setup_queue(chan, {ex, rk, qu, opts})
  when is_bitstring(ex)
  and is_bitstring(rk)
  and is_bitstring(qu)
  and is_list(opts) do
    retry_args = if Keyword.get(opts, :retry, false) do
      [dlx("system.fail"), dlk(qu)]
    else
      []
    end

    args = Keyword.get(opts, :arguments, [])

    {:ok, _stat} = Queue.declare(chan, qu, durable: true, arguments: retry_args ++ args)

    case Keyword.get(opts, :bind, true) do
      true -> :ok = Queue.bind(chan, qu, ex, routing_key: rk)
      false -> :ok = Queue.unbind(chan, qu, ex, routing_key: rk)
      :skip -> :ok
    end

    if Keyword.get(opts, :retry, false) do
      :ok = Queue.bind(chan, qu, "system.retry", routing_key: qu)
    else
      :ok = Queue.unbind(chan, qu, "system.retry", routing_key: qu)
    end
  end

  def with_chan(connection, f) do
    {:ok, chan} = Channel.open(connection)

    try do
      apply(f, [chan])
    after
      Channel.close(chan)
    end
  end
end
