defmodule Proca.Stage.Action do
  @moduledoc """

  # Processing

  Producers:

  - Main action memory queue
    - added by process_async()
    -
  - Process old:
    - blocks
    - returns batch of oldest actions to process
    - when no actions, sleep (is this necessary?)

  Processing:
  - do first part of processing,
  - if this is normal processing, batch: just process and batch :default
  - if this is lookup processing, batch :detail_lookup

  - partition by org_id

  Batcher:
  - default Enum.each process
  - detail_lookup: Enum.each lookup and send over to main action memory queue


  """
  use Broadway
  alias Broadway.Message
  alias Proca.Action
  alias Proca.Stage.Processing
  alias Proca.Pipes.Connection
  require Logger

  @behaviour Broadway.Acknowledger

  def start_link(opts) do
    Broadway.start_link(__MODULE__,
      name: opts[:name] || __MODULE__,
      producer: [
        module: opts[:producer] || {Proca.Stage.Queue, []},
        concurrency: 1,
        transformer: {__MODULE__, :to_message, []}
      ],
      processors: [
        default: [concurrency: opts[:processors_concurrency] || 40]
      ],
      batchers: [
        default: [
          concurrency: 10,
          batch_size: 5,
          batch_timeout: 1000
        ],
        lookup_detail: [
          concurrency: 20,
          batch_size: 5,
          batch_timeout: 3000
        ],
        noop: [
          concurrency: 1
        ]
      ]
    )
  end

  @impl true
  def prepare_messages(messages, _ctx) do
    preloaded_actions =
      messages
      |> Enum.map(& &1.data)
      |> Processing.preload()

    Enum.zip(messages, preloaded_actions)
    |> Enum.map(fn {m, a} -> Message.put_data(m, a) end)
  end

  @impl true
  def handle_message(_, %Message{data: action} = msg, _) do
    case Processing.wrap(action) do
      {:lookup_detail, proc} ->
        msg
        |> Message.put_data(proc)
        |> Message.put_batcher(:lookup_detail)
        |> Message.put_batch_key(Processing.processing_org_id(proc))

      {:process, proc} ->
        msg
        |> Message.put_data(proc)
        |> Message.put_batcher(:default)
        |> Message.put_batch_key(Processing.processing_org_id(proc))

      :noop ->
        msg
        |> Message.ack_immediately()
        |> Message.put_batcher(:noop)
    end
  end

  @impl true
  def handle_batch(:default, msgs, _, _) do
    msgs
    |> process_all()
    |> emit_all()
  end

  @impl true
  def handle_batch(:lookup_detail, msgs, _, _) do
    msgs
    |> lookup_all()
    |> process_all()
    |> emit_all()
  end

  @impl true
  def handle_batch(:noop, msgs, _, _) do
    msgs
  end

  @doc """
  Detail lookup failures do not fail the message: Processing.lookup_detail/1
  falls back to processing without the extra detail so the action still
  proceeds (eg. to sending the normal confirmation email).
  """
  @spec lookup_all([%Message{}]) :: [%Message{}]
  def lookup_all(msgs) do
    map_only_ok(msgs, fn %Message{data: action} = m ->
      {:ok, proc} = Processing.lookup_detail(action)
      Message.put_data(m, proc)
    end)
  end

  def process_all(msgs) do
    map_only_ok(msgs, fn m -> Message.update_data(m, &Processing.process_pipeline/1) end)
  end

  @doc """
  Can fail due to some AMQP publish failure
  """
  def emit_all(msgs) do
    result =
      Connection.with_chan(fn channel ->
        map_only_ok(msgs, fn %{data: data} = m ->
          case Processing.emit(data, channel) do
            :ok -> m
            :error -> Message.failed(m, :publish_error)
          end
        end)
      end)

    case result do
      {:error, reason} ->
        Enum.map(msgs, &Message.failed(&1, inspect(reason)))

      res when is_list(res) ->
        res
    end
  end

  def to_message(%Action{} = action, _opt) do
    %Message{data: action, acknowledger: {__MODULE__, :store, nil}}
  end

  @spec action_page_id(%{
          :__struct__ => Proca.Action | Proca.Stage.Processing,
          optional(any) => any
        }) ::
          any
  def action_page_id(%Action{action_page: %{org_id: org_id}}) do
    org_id
  end

  def action_page_id(%Processing{action_change: %{data: %Action{action_page: %{org_id: org_id}}}}) do
    org_id
  end

  @spec supporter_id(%{:__struct__ => Proca.Action | Proca.Stage.Processing, optional(any) => any}) ::
          any
  def supporter_id(%Action{supporter_id: id}) do
    id
  end

  def supporter_id(%Processing{action_change: %{data: %Action{supporter_id: id}}}) do
    id
  end

  @doc """
  Store!
  """
  @impl true
  def ack(:store, successful, failed) do
    Proca.Repo.checkout(fn ->
      successful
      |> Enum.each(fn
        %{data: %Processing{} = proc} = m ->
          action_id = action_id(proc)

          proc
          |> Processing.clear_transient()
          |> Processing.store!()

          # The MTT test event must be published *after* store! has committed
          # `processing_status`, so the consumer no longer needs to guard against
          # the publish-before-persist race. On failure we only capture to Sentry:
          # an ack can't feed a :failed status back to Broadway, and raising here
          # would crash the whole batch with no retry path.
          #
          # publish_mtt_test_after_store/1 forwards Connection.publish/4's own
          # result, which is `:ok | {:error, term()}` - a reason tuple, not the
          # bare :error atom - so that's the shape matched here.
          case Processing.publish_mtt_test_after_store(proc) do
            :ok ->
              :ok

            {:error, reason} ->
              Logger.warning(
                "MTT test: publish failed after store for action #{action_id}: #{inspect(reason)}"
              )

              Sentry.capture_message("MTT test: publish failed after store",
                extra: %{action_id: action_id, reason: inspect(reason)},
                level: "warning"
              )
          end

          m

        m ->
          m
      end)
    end)

    failed
    |> Enum.each(fn %{status: x} ->
      IO.inspect(x, label: "#{__MODULE__} failed to process actions")
    end)

    :ok
  end

  defp action_id(%Processing{action_change: %Ecto.Changeset{data: %Action{id: id}}}), do: id
  defp action_id(_), do: nil

  @spec map_only_ok([%Message{}], (%Message{} -> %Message{})) :: [%Message{}]
  defp map_only_ok(messages, fun) do
    Enum.map(messages, fn
      %{status: {:failed, _reason}} = m -> m
      m -> fun.(m)
    end)
  end

  def process(%Action{} = a) do
    try do
      [queue] = Broadway.producer_names(__MODULE__)
      Proca.Stage.Queue.enqueue(queue, a)
    catch
      :exit, {:noproc, _} ->
        :ok
    end
  end
end
