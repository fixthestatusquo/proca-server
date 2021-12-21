defmodule Proca.Pipes.Topology do
  @moduledoc """
  Topology of processing queue setup in RabbitMQ.

  Each Org has its own Topology server and set of exchanges/queues. Processing
  load and problems are isolated for each org.

  This Topology service will reconfigure the excahnges and queues when notified
  by Proca.Server.Notify `updated`, `created` and `deleted`. These notifications
  are sent by the API layer when respective event occurs. They are not sent by
  operations on Proca.Org directly.

  (previously responsibility of Proca.Server.Plumbing)

  ### Properties: 

  - 3 exchanges reflect 3 stages of processing (supporter confirms their data, moderator confirms the action, action is delivered)
  - Each exchange has build in worker queues attached, *if workers are enabled*. Worker queues are read by Proca workers.
  - Each exchange has custom queue attached, *if enabled on Org*. Custom queues are meant to be read by external client.
  - Worker and custom queues have a Dead Letter Exchange attached (DLX), so unprocessed messages are temporarily stored there, so they do not clog the processing. They come back after 30 seconds. [Improvement: change this timeout when the retry queue gets bigger]
  - When data is shared with your org by other org, you only receive action onto deliver exchange.
  - Routing key is: `${campaign}.${action_type}`, eg. `no_to_gmo.share`
  - The action format is v1 or v2, depending on `org.action_schema_version`. Defaults to 2 for new Orgs.

  ```
  Action Routing Key: campaign.action_type

  EXCHANGE                 MATCH  QUEUE

  x org.N.confirm.supporter  #  > =wrk.N.email.supporter
                             #  > =cus.N.confirm.supporter

  x org.N.confirm.action     #  > =wrk.N.email.confirm [*]
                             #  > =cus.N.confirm.action

  x org.N.deliver         *.mtt > =wrk.N.email.mtt [*]
                          #     > =wrk.N.email.supporter
                          #     > =wrk.N.sqs              -> proca-gw
                                > =wrk.N.http  [*]        -> proca-gw
                                > =cus.N.deliver

                                    DLX:x org.N.fail fanout> org.N.fail
                                    DLX:x org.N.retry direct:$qn-> =$qn

  Event Routing Key: event_type.sub_type

  x org.N.event      # > =wrk.N.event.webhook
                     # > =cus.N.event

  [*] - not yet implemented
  ```

  ### Enabled Queues.

  - Custom queues are enabled by flags on Org (boolean columns):
    - `custom_supporter_confirm` enables `cus.N.supporter.confirm`
    - `custom_action_confirm` enables `cus.N.action.confirm`
    - `custom_action_deliver` enables `cus.N.deliver`

  - Worker queues, are enabled by flags on Org (boolean columns):
    - `system_sqs_deliver` sends to SQS (SQS service must be configured)
    - `email.supporter` sends double-opt-in email when: `email_opt_in` is TRUE, and `email_opt_in_template` is set on Org. Org must have email/template backends set.
    - `email.supporter` sends thank you emails when Org has email/template backends set. The worker will send emails if ActionPage.thank_you_tempalte_ref refers to template identifier in the backend.


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

  def whereis(o = %Org{}) do
    {:via, Registry, {reg, nam}} = process_name(o)
    case Registry.lookup(reg, nam) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  ## Callbacks
  @impl true
  def init(org = %Org{id: org_id}) do
    config = configuration(org)
    Pipes.Connection.with_chan fn chan ->
      declare_exchanges(chan, org)
      declare_retry_circuit(chan, org)
      declare_worker_queues(chan, org, config)
      declare_custom_queues(chan, org)
    end

    # Setup queues (without the Broadway ones)
    {:ok, %{org_id: org_id, configuration: config}}
  end

  @impl true
  def handle_call({:configuration_change?, org = %Org{}}, _from, st = %{configuration: current}) do
    {
      :reply,
      configuration(org) != current,
      st
    }
  end


  def configuration(o = %Org{}) do
    %{
      confirm_supporter: Stage.EmailSupporter.start_for?(o) and o.email_opt_in and is_bitstring(o.email_opt_in_template),
      email_supporter: Stage.EmailSupporter.start_for?(o),
      sqs: Stage.SQS.start_for?(o),
      webhook:  Stage.Webhook.start_for?(o)
    }
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
    :ok = Exchange.declare(chan, xn(o, "event"), :fanout, durable: true) # TODO -> topic or direct?
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

  def declare_worker_queues(chan, o = %Org{}, config) do
    [
      {
        xn(o, "confirm.supporter"),
        wqn(o, "email.supporter"),
        bind: config[:confirm_supporter],
        route: "#"
      },

      {
        xn(o, "deliver"),
        wqn(o, "email.supporter"),
        bind: config[:email_supporter],
        route: "#"
      },

      {
        xn(o, "deliver"),
        wqn(o, "sqs"),
        bind: config[:sqs],
        route: "#"
      },

      {
        xn(o, "event"),
        wqn(o, "webhook"),
        bind: config[:webhook],
        route: "#"
      }
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
    # IO.inspect({exchange_name, queue_name, o.name, [bind: bind?]}, label: "declare retrying queue")

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
