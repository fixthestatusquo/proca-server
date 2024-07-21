defmodule Proca.Pipes.Topology do
  @moduledoc """
  Topology of processing queue setup in RabbitMQ.

  Each Org has its own Topology server and set of exchanges/queues. Processing
  load and problems are isolated for each org.

  This Topology service will reconfigure the excahnges and queues when notified
  by Proca.Server.Notify `updated`, `created` and `deleted`. These notifications
  are sent by the API layer when respective event occurs. They are not sent by
  operations on Proca.Org directly.

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

  x org.N.deliver
                          #     > =wrk.N.email.supporter
                          #     > =cus.N.deliver
                          #     > =wrk.N.webhook
                          #     > =wrk.N.sqs

                                    DLX:x org.N.fail fanout> org.N.fail
                                    DLX:x org.N.retry direct:$qn-> =$qn

  Event Routing Key: event_type.sub_type

  x org.N.event      # > =wrk.N.webhook
                     # > =wrk.N.sqs
                     # > =cus.N.deliver

  [*] - not yet implemented
  ```

  ### Enabled Queues.

  - Custom queues are enabled by flags on Org (boolean columns):
    - `custom_supporter_confirm` enables `cus.N.supporter.confirm`
    - `custom_action_confirm` enables `cus.N.action.confirm`
    - `custom_action_deliver` enables `cus.N.deliver`

  - Worker queues, are enabled by flags on Org (boolean columns):
    - `email.supporter` sends double-opt-in email when: `supporter_confirm` is `true`. Org must have email/template backends set. The email will be set if `email_supporter_template` is set on org or action page.
    - `email.supporter` sends thank you emails when Org has email/template backends set. The worker will send emails if ActionPage.thank_you_template refers to template identifier in the backend.
    - `sqs` - sends action data to AWS SQS
    - `webhook` -sends action data to Webhook backend


  """
  use GenServer
  require Logger
  alias Proca.Org
  alias Proca.Pipes
  alias Proca.Stage
  alias AMQP.{Queue, Exchange}

  ## API for topology server lifecycle
  def start_link(org = %Org{}) do
    GenServer.start_link(__MODULE__, org, name: process_name(org))
  end

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

    Pipes.Connection.with_chan(fn chan ->
      declare_exchanges(chan, org)
      declare_retry_circuit(chan, org)
      declare_worker_queues(chan, org, config)
      declare_custom_queues(chan, org, config)
    end)

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

  defp push_backend(%Org{push_backend: %{name: name}}), do: name
  defp push_backend(_), do: nil
  defp event_backend(%Org{event_backend: %{name: name}}), do: name
  defp event_backend(_), do: nil

  def configuration(o = %Org{}) do
    instance = Org.one([:instance] ++ [preload: [:push_backend, :event_backend]])
    o = Proca.Repo.preload(o, [:push_backend, :event_backend])

    %{
      confirm_supporter: Stage.EmailSupporter.start_for?(o) and o.supporter_confirm,
      email_supporter: Stage.EmailSupporter.start_for?(o),
      push_sqs: Stage.SQS.start_for?(o) and push_backend(o) == :sqs,
      push_webhook: Stage.Webhook.start_for?(o) and push_backend(o) == :webhook,
      custom_supporter_confirm: o.custom_supporter_confirm,
      custom_action_confirm: o.custom_action_confirm,
      custom_action_deliver: o.custom_action_deliver,
      custom_event_deliver: o.custom_event_deliver,
      event_sqs: Stage.SQS.start_for?(o) and event_backend(o) == :sqs,
      event_webhook: Stage.Webhook.start_for?(o) and event_backend(o) == :webhook,
      event_forward_to_instance_sqs:
        Stage.SQS.start_for?(instance) and event_backend(instance) == :sqs,
      event_forward_to_instance_webhook:
        Stage.Webhook.start_for?(instance) and event_backend(instance) == :webhook,
      event_forward_to_instance_custom: instance.custom_event_deliver,
      instance_org_id: instance.id
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
    # TODO -> topic or direct?
    # # migrate queues
    # ex=$(rabbitmqadmin  list exchanges -f long -V proca | grep event |cut -f 2 -d ' '); for e in $ex; do rabbitmqadmin delete exchange name=$e -V proca; done
    # in elixir
    # Proca.Org.all([]) |> Enum.each(&Proca.Pipes.Supervisor.reload_child/1)
    #
    :ok = Exchange.declare(chan, xn(o, "event"), :topic, durable: true)
  end

  def declare_retry_circuit(chan, o = %Org{}) do
    # fail queue = fail exchange
    qn = xn(o, "fail")

    Queue.declare(chan, qn,
      durable: true,
      arguments: [
        {"x-dead-letter-exchange", :longstr, xn(o, "retry")}
        #        {"x-message-ttl", :long, round(sec * 1000)}
      ]
    )

    Queue.bind(chan, qn, qn)
  end

  def declare_custom_queues(chan, o = %Org{}, config) do
    [
      {xn(o, "confirm.supporter"), cqn(o, "confirm.supporter"),
       bind: config[:custom_supporter_confirm], route: "#"},
      {xn(o, "confirm.action"), cqn(o, "confirm.action"),
       bind: config[:custom_action_confirm], route: "#"},
      {xn(o, "deliver"), cqn(o, "deliver"), bind: config[:custom_action_deliver], route: "#"},
      {xn(o, "event"), cqn(o, "deliver"), bind: config[:custom_event_deliver], route: "#"}
    ]
    |> Enum.each(fn x -> declare_retrying_queue(chan, o, x) end)
  end

  def declare_worker_queues(chan, o = %Org{}, config) do
    instance = %Org{id: config[:instance_org_id]}

    [
      {
        xn(o, "confirm.supporter"),
        wqn(o, "email.supporter"),
        bind: config[:confirm_supporter], route: "#"
      },
      {
        xn(o, "deliver"),
        wqn(o, "email.supporter"),
        bind: config[:email_supporter], route: "#"
      },
      {
        xn(o, "deliver"),
        wqn(o, "sqs"),
        bind: config[:push_sqs], route: "#"
      },
      {
        xn(o, "event"),
        wqn(o, "sqs"),
        bind: config[:event_sqs], route: "#"
      },
      {
        xn(o, "deliver"),
        wqn(o, "webhook"),
        bind: config[:push_webhook], route: "#"
      },
      {
        xn(o, "event"),
        wqn(o, "webhook"),
        bind: config[:event_webhook], route: "#"
      }
    ]
    |> Enum.each(fn x -> declare_retrying_queue(chan, o, x) end)

    [
      # Plug instance to the event queues
      {
        xn(o, "event"),
        wqn(instance, "sqs"),
        bind: config[:event_forward_to_instance_sqs], route: "system.*"
      },
      {
        xn(o, "event"),
        wqn(instance, "webhook"),
        bind: config[:event_forward_to_instance_webhook], route: "system.*"
      },
      {
        xn(o, "event"),
        cqn(instance, "deliver"),
        bind: config[:event_forward_to_instance_custom], route: "system.*"
      }
    ]
    |> Enum.each(fn x -> bind_queue(chan, x) end)
  end

  def retry_queue_arguments(o = %Org{}, queue_name) do
    [
      {"x-dead-letter-exchange", :longstr, xn(o, "fail")},
      {"x-dead-letter-routing-key", :longstr, queue_name}
    ]
  end

  def declare_retrying_queue(
        chan,
        o = %Org{},
        {exchange_name, queue_name, [bind: bind?, route: rk]}
      ) do
    # IO.inspect({exchange_name, queue_name, o.name, [bind: bind?]}, label: "declare retrying queue")

    if bind? do
      Queue.declare(chan, queue_name,
        durable: true,
        arguments: retry_queue_arguments(o, queue_name)
      )

      :ok = Queue.bind(chan, queue_name, exchange_name, routing_key: rk)
      :ok = Queue.bind(chan, queue_name, xn(o, "retry"), routing_key: queue_name)
    else
      :ok = Queue.unbind(chan, queue_name, exchange_name, routing_key: rk)
      # do not unbind the retry queue because some messages might bewaiting for a retry there
      # and we do not want to just throw them away
    end
  end

  def bind_queue(
        chan,
        {exchange_name, queue_name, [bind: bind?, route: rk]}
      ) do
    if bind? do
      :ok = Queue.bind(chan, queue_name, exchange_name, routing_key: rk)
    else
      :ok = Queue.unbind(chan, queue_name, exchange_name, routing_key: rk)
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
