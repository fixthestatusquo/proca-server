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

  At the moment we do not support custom action confirmation - fully - we do not send actions to this queue and there is not routes in API to confirm or reject an action.
  This is a missing piece albeit for now did not proove necessary.
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
  This function implements the state machine for Action.
  It returns a new states for action and supporter, as well a queue stage where to emit the action.
  {action_state, supporter_state, queue_stage}

  returns :ok if nothing needs to be done
  """
  @spec transition(%Action{}, %ActionPage{}) ::
          :ok
          | {:new | :confirming | :accepted | :delivered, :new | :confirming | :accepted,
             :supporter_confirm | :action_confirm | :deliver | nil}
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
        action = %{
          processing_status: :new,
          supporter: %{processing_status: :new}
        },
        %ActionPage{
          org: %{
            supporter_confirm: system_confirm,
            custom_supporter_confirm: custom_confirm,
            custom_action_confirm: action_confirm
          }
        }
      ) do
    # if we confirm supporter whether the system (emails) or custom (queue) methods are enabled
    cond do
      system_confirm or custom_confirm ->
        {:new, :confirming, :supporter_confirm}

      action_confirm ->
        {:confirming, :accepted, :action_confirm}

      true ->
        {:delivered, :accepted, :deliver}
    end
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
        action = %{
          processing_status: action_status,
          supporter: %{processing_status: :rejected}
        },
        _ap
      )
      when action_status in [:new, :rejected] do
    #
    # Supporter was rejected, reject also the actions
    {:rejected, :rejected, nil}
  end

  # Supporter is accepted, and we do not confirm action, lets move to delivery
  def transition(
        action = %{
          processing_status: :new,
          supporter: %{processing_status: :accepted}
        },
        %ActionPage{
          org: %{custom_action_confirm: true}
        }
      ) do
    # Send action to action_confirm queue
    {:confirming, :accepted, :action_confirm}
  end

  def transition(
        %{
          processing_status: :confirming,
          supporter: %{processing_status: :accepted}
        },
        _ap
      ) do
    # Action is being confirmed, no action
    :ok
  end

  def transition(
        %{
          processing_status: :rejected,
          supporter: %{processing_status: :accepted}
        },
        _ap
      ) do
    # Action has ben rejected, no action
    :ok
  end

  # Supporter is accepted, action got accepted or we did not need action confirm -> deliver
  def transition(
        action = %{
          processing_status: action_status,
          supporter: %{processing_status: :accepted}
        },
        %ActionPage{}
      )
      when action_status in [:new, :accepted] do
    # Send action to confirm_action queue
    {:delivered, :accepted, :deliver}
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

  ## Processing pipeline steps!

  def change_status({action_ch, supporter_ch}, action_status, supporter_status) do
    {
      change(action_ch, processing_status: action_status),
      change(supporter_ch, processing_status: supporter_status)
    }
  end

  @doc """
  Rank supporter when entering:
  1. supporter confirm stage
  2. action confirm stage
  3. action delivery stage
  """
  def maybe_rank_supporter({a, changeset}, queue_stage) when queue_stage != nil do
    {a, Supporter.naive_rank(changeset)}
  end

  def maybe_rank_supporter(changesets, nil), do: changesets

  @doc """
  If we are emitting to queue, do the lookup and modify supporter and/or action
  """
  def lookup_detail({action_ch, supporter_ch}, queue_stage, org) when queue_stage != nil do
    alias Proca.Service.Detail

    case Detail.lookup(org, supporter_ch.data) do
      {:ok, details} ->
        {s, a} = Detail.update(supporter_ch, action_ch)
        # in Processing action goes first..
        {a, s}

      {:error, reason} ->
        {action_ch, supporter_ch}
    end
  end

  def lookup_details(changesets, nil, _), do: changesets

  # XXX operate on a changeset!!!! and do not run a nested tx
  def clear_transient({action_ch, supporter_ch}, :deliver) do
    {
      Action.clear_transient_fields(action_ch),
      Supporter.clear_transient_fields(supporter_ch)
    }
  end

  def clear_transient(changesets, _), do: changesets

  @doc """
  This method emits an effect on transition.

  We send whole action data, because a different system will consume it straight
   from rabbitmq.

  """
  @spec emit(action :: %Action{}, :action_confirm | :supporter_confirm | :deliver) :: :ok | :error
  def emit(action, :deliver) when not is_nil(action) do
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

  def emit(action, entity, stage) when not is_nil(action) do
    routing = routing_for(action)
    exchange = exchange_for(action.action_page.org, stage)

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

  def exchange_for(org, :supporter_confirm) do
    Proca.Pipes.Topology.xn(org, "confirm.supporter")
  end

  def exchange_for(org, :action_confirm) do
    Proca.Pipes.Topology.xn(org, "confirm.action")
  end

  def exchange_for(org, :action, :deliver) do
    Proca.Pipes.Topology.xn(org, "deliver")
  end

  @spec process(action :: %Action{}) :: :ok
  def process(action = %Action{}) do
    # Make sure we have all necessary associated data.
    # In usual case, this action is already preloaded, so there is no database access here.
    action =
      Repo.preload(action,
        action_page: [:org, :campaign],
        supporter: [:action_page, [contacts: :org]]
      )

    action_ch = change(action)
    supporter_ch = change(action.supporter)

    emit_and_save = fn ->
      case emit(action, thing, stage) do
        :ok ->
          Repo.update!(state_change)

        :error ->
          error("Failed to publish #{thing} #{stage}")
          Repo.rollback(:publish_failed)
      end
    end

    case transition(action, action.action_page) do
      {action_state, supporter_state, stage} ->
        {action_ch, supporter_ch} =
          change_state(action, action_state, supporter_state)
          |> maybe_rank_supporter(stage)
          |> lookup_detail(stage, action.action_page.org)

      {state_change, thing, stage} ->
        Repo.transaction()

        :ok

      :ok ->
        :ok
    end
  end
end
