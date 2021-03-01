defmodule Proca.Pipes.Topology do
  @moduledoc """
  Topology of processing queue setup in RabbitMQ.

  Each Org has its own Topology server and set of exchanges/queues. Processing
  load and problems are isolated for each org.

  (previously responsibility of Proca.Server.Plumbing)

  [action/supporter] RK: campaign.action_type

  x org.N.confirm.supporter    #> =wrk.N.email.optin=
                               #> =cus.N.confirm.supporter

  x org.N.confirm.action       #> =wrk.N.email.confirm
                               #> =cus.N.confirm.action [2]

  x org.N.deliver   [1]   *.mtt > =wrk.N.email.mtt=
                          #     > =wrk.N.sqs              -> proca-gw
                                > =wrk.N.http             -> proca-gw
                                > =cus.N.deliver

                                    DLX:x org.N.fail fanout> org.N.fail
                                    DLX:x org.N.retry direct:$qn-> =$qn=


  Caveats:

  1 - from here a cross-link if it's a partner org? But delivery based on consents, no queue. Also the delivery in such case is just for CRM right ?
  2 - need implemnetation of Confirms - with special confirm code (cc)

  """
  use GenServer
  require Logger
  alias Proca.Org
  alias Proca.Pipes
  alias Proca.Stage
  alias AMQP.{Channel, Queue, Exchange}
  import AMQP.Basic

  ## API for topology server lifecycle
  def start_link(org = %Org{}), do: GenServer.start_link(__MODULE__, org, name: process_name(org))

  def stop(org = %Org{}), do: GenServer.stop(process_name(org))

  defp process_name(%Org{id: org_id}) do
    {:via, Registry, {Proca.Pipes.Registry, {__MODULE__, org_id}}}
  end

  ## Callbacks
  def init(org = %Org{id: org_id}) do
    {:ok, chan} = Channel.open(Pipes.Connection.connection)

    try do
      declare_exchanges(chan, org)
      declare_retry_circuit(chan, org)
      declare_worker_queues(chan, org)
      declare_custom_queues(chan, org)
    rescue
      _ -> Channel.close(chan)
    end

    # Setup queues (without the Broadway ones)
    {:ok, %{org_id: org_id}}
  end

  @doc "Exchange name for an org, name is exchange name (stage name org fail, retry)"
  def xn(%Org{id: id}, name), do: "org.#{id}.#{name}"

  @doc "Name of queue to which a worker is attached (like for email, SQS)"
  def wqn(%Org{id: id}, name), do: "wrk.#{id}.#{name}"

  @doc "Name of queue for custom use (usually name is stage name)"
  def cqn(%Org{id: id}, name), do: "cus.#{id}.#{name}"

  def declare_exchanges(chan, o = %Org{}) do
    :ok = Exchange.declare(chan, xn(o, "confirm.supporter"), :topic, durable: true)
    :ok = Exchange.declare(chan, xn(o, "confirm.action"), :topic, durable: true)
    :ok = Exchange.declare(chan, xn(o, "deliver"), :topic, durable: true)
    :ok = Exchange.declare(chan, xn(o, "fail"), :fanout, durable: true)
    :ok = Exchange.declare(chan, xn(o, "retry"), :direct, durable: true)
  end

  def declare_retry_circuit(chan, o = %Org{}) do
    sec = 30
    # fail queue = fail exchange
    qn = xn(o, "fail")

    Queue.declare(chan, qn, durable: true, arguments: [
          {"x-dead-letter-exchange", :longstr, xn(o, "retry")},
          {"x-message-ttl", :long, round(sec * 1000)}
        ])
    Queue.bind(chan, qn, qn)
  end

  def declare_custom_queues(chan, o = %Org{}) do
    [
      {xn(o, "confirm.supporter"), cqn(o, "confirm.supporter"), bind: o.custom_supporter_confirm, route: "#"},
      {xn(o, "confirm.action"), cqn(o, "confirm.action"), bind: o.custom_action_confirm, route: "#"},
      {xn(o, "deliver"), cqn(o, "deliver"), bind: o.custom_action_deliver, route: "#"}
    ]
    |> Enum.each(fn x -> declare_retrying_queue(chan, o, x) end)
  end

  def declare_worker_queues(chan, o = %Org{}) do
    [
      {
        xn(o, "confirm.supporter"),
        wqn(o, "email.supporter"),
        bind: Stage.ThankYou.start_for?(o) and o.email_opt_in and is_bitstring(o.email_opt_in_template),
        route: "#"
      },

      {
        xn(o, "deliver"),
        wqn(o, "email.supporter"),
        bind: Stage.ThankYou.start_for?(o),
        route: "#"
      },

      {
        xn(o, "deliver"),
        wqn(o, "sqs"),
        bind: Stage.SQS.start_for?(o),
        route: "#"
      },
    ]
    |> Enum.each(fn x -> declare_retrying_queue(chan, o, x) end)
  end

  def retry_queue_arguments(o = %Org{}, queue_name) do
    [
      {"x-dead-letter-exchange", :longstr, xn(o, "fail")},
      {"x-dead-letter-routing-key", :longstr, queue_name}
    ]
  end

  def declare_retrying_queue(chan, o = %Org{}, {exchange_name, queue_name, [bind: bind?, route: rk]}) do
    IO.inspect({exchange_name, queue_name, o.name, [bind: bind?]}, label: "declare retrying queue")

    if bind? do
      Queue.declare(chan, queue_name, durable: true, arguments: retry_queue_arguments(o, queue_name))
      :ok = Queue.bind(chan, queue_name, exchange_name, routing_key: rk)
      :ok = Queue.bind(chan, queue_name, xn(o, "retry"), routing_key: queue_name)
    else
      :ok = Queue.unbind(chan, queue_name, exchange_name, routing_key: rk)
      # do not unbind the retry queue because some messages might bewaiting for a retry there
      # and we do not want to just throw them away
    end
  end

  def broadway_producer(o = %Org{}, work_type) do
    queue_name = wqn(o, work_type)
    {
      BroadwayRabbitMQ.Producer,
      queue: queue_name,
      connection: Proca.Pipes.Connection.connection_url(),
      qos: [
        prefetch_count: 10
      ],
      on_failure: :reject,
      metadata: [:headers]
    }
  end
end
