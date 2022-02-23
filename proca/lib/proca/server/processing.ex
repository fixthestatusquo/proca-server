defmodule Proca.Server.Processing do
  use GenServer
  alias Proca.Repo
  alias Proca.{Action, ActionPage, Supporter, Field}
  alias Proca.Pipes.Connection
  import Proca.Stage.Support, only: [action_data: 2, action_data: 3]
  import Ecto.Changeset
  import Logger

  @moduledoc """
  For these cases:
  1. We receive Actions with Supporter or with unbound ref.
  2. Action with supporter may have new or resolved supporter (by ref).
  3. Action with unbound ref will be bound later.

  Processing works in following way:
  1. Process supporter, then action.
  2. Process supporter.
  3. ignore. This is a case where we store action for counts (share, tweet
  without any contact, and it might never arrive). On the other hand, it would be nice to have this later in CRM right? 

  State diagram below shows transitions while processing. `A` stands for Action,
  `S` for supporter. States are enumerated in `ProcessingStatus`, and supporter
  and action track its status separately.

  ```
      [ A(NEW) / nil ]
          | linking
          v
      [ A(NEW) / S(NEW) ]            <-----.  linking new action to rejected supporter
          | emit to supporter confirm      | 
          v                                |  
      [ A(NEW) / S(CONFIRMING)] -> [ A(REJECTED) / S(REJECTED) ] --> stop (and remove the cookie?!)
          | confirm 
          v
    ,->[ A(NEW) / S(ACCEPTED)]
    |     | emit to action confirm
  n |     v
  e |  [ A(CONFIRMING) / S(ACCEPTED)] -> [ A(REJECTED) / S(ACCEPTED)] --> stop
  w |     | confirm
    |     v
    '--[ A(ACCEPTED) / S(ACCEPTED)] -> [ A(DELIVERED) / S(ACCEPTED)] --> stop
                                   emit
  ```
  This mechanism is supposed to be able to run many times with same result if
  action and supporter bits do not change.

  We need:
  - supporter.confirming
  - supporter.confirmed
  - action.confirming
  - action.confirmed
  - action.delivered

  XXX for MVP, we assume:

  ActionPage does not require Supporter confirmation, supporter :new -> :accepted
  ActionPage does not require Action confirmation, goes from :new -> :accepted
  But it is pushed to delivery queue and chnaged to :delivered (after processing in Broadway?)
  """

  @impl true
  def init([]) do
    {:ok, []}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def handle_cast({:action, action}, state) do
    process(action)
    {:noreply, state}
  end

  @impl true
  def handle_call(:sync, _from, state) do
    {:reply, :ok, state}
  end

  def process_async(action) do
    GenServer.cast(__MODULE__, {:action, action})
  end

  @doc """
  A noop sync method that lets you make sure all previous async messages were processed (used in testing)
  """
  def sync do
    GenServer.call(__MODULE__, :sync)
  end

  @doc """
  This function implements the state machine for Action. It returns a changeset to update action/supporter (state) and atoms telling where to route action.
  """
  @spec transition(%Action{}, %ActionPage{}) ::
          :ok
          | {Ecto.Changeset.t(%Action{}), :action | :supporter, :confirm | :deliver}
          | {Ecto.Changeset.t(%Action{}), nil, nil}
  def transition(
        %{
          processing_status: :new,
          supporter: nil
        },
        _ap
      ) do
    # Action without any supporter associated: not processing.
    :ok
  end

  def transition(
        %{
          processing_status: :delivered,
          supporter: %{processing_status: :accepted}
        },
        _ap
      ) do
    # Action already delivered: not processing.
    :ok
  end

  def transition(
        %{
          processing_status: :new,
          supporter: %{processing_status: :confirming}
        },
        _ap
      ) do
    # Supporter is being confirmed, so this action has to wait
    :ok
  end

  def transition(
        action = %{
          processing_status: :new,
          supporter: %{processing_status: :rejected}
        },
        _ap
      ) do
    # Supporter was rejected, reject also the actions
    {
      change_status(action, :rejected, :rejected),
      nil,
      nil
    }
  end

  def transition(
        action = %{
          processing_status: action_status,
          supporter: %{processing_status: :accepted}
        },
        %ActionPage{live: live}
      )
      when action_status in [:new, :accepted] do
    # do the moderation (via email?) XXX need the thank_you handler
    # go strainght to delivered
    {
      change_status(action, :delivered, :accepted),
      :action,
      :deliver
    }
  end

  # Needs double opt-in 
  def transition(
        action = %{
          processing_status: :new,
          supporter: %{processing_status: :new}
        },
        %ActionPage{org: %{supporter_confirm: opt_in}}
      ) do
    # we should handle confirmation if required, but before it's implemented let's accept supporter
    # and instantly go to delivery

    if opt_in do
      {
        change_status(action, :new, :confirming),
        :supporter,
        :confirm
      }
    else
      {
        change_status(action, :delivered, :accepted),
        :action,
        :deliver
      }
    end
  end

  def transition(
        %{
          processing_status: :delivered
        },
        _ap
      ) do
    # Action already delivered
    :ok
  end

  def change_status(action, action_status, supporter_status) do
    sup = change(action.supporter, processing_status: supporter_status)
    act = change(action, processing_status: action_status)

    if act.changes == %{} do
      sup
    else
      if sup.changes == %{} do
        act
      else
        change(act, supporter: sup)
      end
    end
  end

  @doc """
  This method emits an effect on transition.

  We send whole action data, because a different system will consume it straight
   from rabbitmq.

  """
  @spec emit(action :: %Action{}, :action | :supporter, :confirm | :deliver) :: :ok | :error
  def emit(action, :action, :deliver) when not is_nil(action) do
    publish_for = fn %Proca.Contact{org_id: org_id} ->
      routing = routing_for(action)
      exchange = exchange_for(%Proca.Org{id: org_id}, :action, :deliver)
      data = action_data(action, :deliver, org_id)
      Connection.publish(exchange, routing, data)
    end

    with true <- Enum.all?(action.supporter.contacts, &(publish_for.(&1) == :ok)),
         :ok <- clear_transient(action) do
      :ok
    else
      _ -> :error
    end
  end

  def emit(action, entity, :confirm) when not is_nil(action) do
    routing = routing_for(action)
    exchange = exchange_for(action.action_page.org, entity, :confirm)

    stage = if entity == :action, do: :action_confirm, else: :supporter_confirm

    data = action_data(action, stage)

    with :ok <- Connection.publish(exchange, routing, data) do
      :ok
    else
      _ -> :error
    end
  end

  def emit(_action, nil, nil), do: :ok

  def routing_for(%{action_type: at, campaign: %{name: cname}}) do
    at <> "." <> cname
  end

  def routing_for(%{action_type: at, action_page: %{campaign: %{name: cname}}}) do
    at <> "." <> cname
  end

  def exchange_for(org, :supporter, :confirm) do
    Proca.Pipes.Topology.xn(org, "confirm.supporter")
  end

  def exchange_for(org, :action, :confirm) do
    Proca.Pipes.Topology.xn(org, "confirm.action")
  end

  def exchange_for(org, :action, :deliver) do
    Proca.Pipes.Topology.xn(org, "deliver")
  end

  @spec process(action :: %Action{}) :: :ok
  def process(action = %Action{}) do
    action =
      Repo.preload(action,
        action_page: [:org, :campaign],
        supporter: [:action_page, [contacts: :org]]
      )

    case transition(action, action.action_page) do
      {state_change, thing, stage} ->
        Repo.transaction(fn ->
          case emit(action, thing, stage) do
            :ok ->
              Repo.update!(state_change)

            :error ->
              error("Failed to publish #{thing} #{stage}")
              Repo.rollback(:publish_failed)
          end
        end)

        :ok

      :ok ->
        :ok
    end
  end

  def clear_transient(action) do
    tx = Ecto.Multi.new()

    tx =
      case Supporter.clear_transient_fields_query(action.supporter) do
        :noop -> tx
        query -> Ecto.Multi.update_all(tx, :supporter, query, [])
      end

    tx =
      case Action.clear_transient_fields_query(action) do
        :noop -> tx
        q -> Ecto.Multi.update_all(tx, :action, q, [])
      end

    {:ok, _} = Repo.transaction(tx)

    :ok
  end
end
