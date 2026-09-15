defmodule Proca.Stage.Processing do
  alias Proca.Repo
  alias Proca.{Action, ActionPage, Supporter}
  alias Proca.Pipes.Connection
  import Proca.Stage.Support, only: [action_data: 2, action_data: 3]
  import Ecto.Changeset
  import Logger
  alias __MODULE__

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
  `S` for supporter. States are enumerated in ActionProcessingStatus / SupporterProcessingStatus (see `Enums`), and supporter
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

  A rejected suppoter or action will not be counted into the statistics for the campaign.

  A bounce event received from email backend will mark both the `Supporter` and
  the `Action` as rejected (even if they were accepted before).
  """

  defstruct action_change: nil,
            supporter_change: nil,
            details: nil,
            new_state: {:new, :new},
            stage: nil

  @doc """
  Prepare the action associated data - arg can be single action or a list.
  In usual case, this action is already preloaded, so there is no database access here.
  """
  def preload(actions) do
    Repo.preload(actions,
      action_page: [[org: :detail_backend], :campaign],
      supporter: [:action_page, [contacts: :org]]
    )
  end

  def processing_org_id(%Processing{action_change: %{data: %{action_page: %{org_id: id}}}}),
    do: id

  @doc """
  Wrap Action in a Processing state

  2. Check which stage we are at
  2. Check if we need detail lookup.
  3. If so, run the lookup task and exit -> a continuation will come via handle_info() and we continue in process_pipeline
  4. Else run straight process_pipeline
  """
  @spec wrap(%Action{}) :: :noop | {:lookup_detail, %Processing{}} | {:process, %Processing{}}
  def wrap(action = %Action{}) do
    case transition(action, action.action_page) do
      :ok ->
        :noop

      {action_state, supporter_state, stage} ->
        p = %Processing{
          action_change: change(action),
          supporter_change: change(action.supporter),
          new_state: {action_state, supporter_state},
          stage: stage
        }

        if needs_lookup?(action, stage) do
          {:lookup_detail, p}
        else
          {:process, p}
        end
    end
  end

  def process_pipeline(%Processing{} = p) do
    p
    |> change_status()
    |> rank_supporter()
  end

  def needs_lookup?(%Action{action_page: %{org: %{detail_backend_id: srv_id}}}, stage)
      when is_number(srv_id) and stage != nil,
      do: true

  def needs_lookup?(_, _), do: false

  @doc """
  Tri-state override of org.custom_action_confirm by campaign.action_confirm:
  nil defers to the org setting, true/false force it on or off for this campaign.
  """
  @spec effective_action_confirm(boolean(), boolean() | nil) :: boolean()
  def effective_action_confirm(org_action_confirm, nil), do: org_action_confirm

  def effective_action_confirm(_org_action_confirm, campaign_action_confirm),
    do: campaign_action_confirm

  @spec effective_supporter_confirm(boolean(), boolean() | nil) :: boolean()
  def effective_supporter_confirm(org_supporter_confirm, nil), do: org_supporter_confirm
  def effective_supporter_confirm(_org_supporter_confirm, campaign_supporter_confirm), do: campaign_supporter_confirm

  @spec transition(%Action{}, %ActionPage{}) ::
          :ok
          | {:new | :confirming | :accepted | :delivered | :rejected,
             :new | :confirming | :accepted | :rejected,
             :supporter_confirm | :action_confirm | :deliver | nil}
  @doc """
  This function implements the state machine for Action.
  It returns a new states for action and supporter, as well a queue stage where to emit the action.
  {action_state, supporter_state, queue_stage}

  returns :ok if nothing needs to be done
  """
  # Is it already delivered?
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
          supporter: nil
        },
        _ap
      ) do
    # Action without any supporter associated: not processing.
    :ok
  end

  def transition(
        %{
          processing_status: :new,
          supporter: %{processing_status: :new}
        },
        %ActionPage{
          org: %{
            supporter_confirm: system_confirm,
            custom_supporter_confirm: custom_confirm,
            custom_action_confirm: org_action_confirm
          },
          campaign: %{
            supporter_confirm: campaign_confirm,
            action_confirm: campaign_action_confirm
          }
        }
      ) do
    # if we confirm supporter whether the system (emails) or custom (queue) methods are enabled
    cond do
      effective_supporter_confirm(system_confirm or custom_confirm, campaign_confirm) ->
        {:new, :confirming, :supporter_confirm}

      effective_action_confirm(org_action_confirm, campaign_action_confirm) ->
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

  # Action without consent, when supporter is new -> leave it, the with_consent: true should trigger processing the supporter, otherwise we have a race
  def transition(
        %{
          processing_status: :new,
          with_consent: false,
          supporter: %{processing_status: :new}
        },
        %ActionPage{}
      ) do
    :ok
  end

  # The only emitting transition at the moment!
  # Supporter is accepted, and we do not confirm action, lets move to delivery
  def transition(
        %{
          processing_status: :new,
          with_consent: true,
          supporter: %{processing_status: :accepted}
        },
        %ActionPage{
          org: %{custom_action_confirm: org_action_confirm},
          campaign: %{action_confirm: campaign_action_confirm}
        }
      )
      when (is_nil(campaign_action_confirm) and org_action_confirm == true) or
             campaign_action_confirm == true do
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
        %{
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

  def transition(%{processing_status: :repeat}, _ap) do
    :ok
  end

  ## Processing pipeline steps!

  def change_status(
        p = %{action_change: a, supporter_change: s, new_state: {action_status, supporter_status}}
      ) do
    %{
      p
      | action_change: change(a, processing_status: action_status),
        supporter_change: change(s, processing_status: supporter_status)
    }
  end

  @doc """
  Rank supporter when entering:
  1. supporter confirm stage
  2. action confirm stage
  3. action delivery stage
  """
  def rank_supporter(
        p = %Processing{
          supporter_change: changeset,
          action_change: action_ch,
          stage: queue_stage
        }
      )
      when queue_stage != nil do
    {ranked_ch, same_page} = Supporter.naive_rank(changeset)

    action_ch =
      if same_page and Ecto.Changeset.get_change(ranked_ch, :dupe_rank, 0) > 0 and
           Ecto.Changeset.get_change(action_ch, :processing_status) == :delivered do
        change(action_ch, processing_status: :repeat)
      else
        action_ch
      end

    %{p | supporter_change: ranked_ch, action_change: action_ch}
  end

  def rank_supporter(p), do: p

  @doc """
  If we are emitting to queue, do the lookup and modify supporter and/or action.

  If the lookup fails (backend down, bad response, not found...) we do not
  block the action: we proceed without the extra detail, so eg. the
  supporter still gets the normal (two-button) confirmation email instead of
  getting stuck retrying the lookup forever.
  """
  @spec lookup_detail(%Processing{}) :: {:ok, %Processing{}}
  def lookup_detail(p = %{action_change: action_ch, supporter_change: supporter_ch, stage: stage})
      when stage != nil do
    alias Proca.Service.Detail

    org = action_ch.data.action_page.org

    case Detail.lookup(org, supporter_ch.data) do
      {:ok, details} ->
        {s, a} = Detail.update(supporter_ch, action_ch, details)
        {:ok, %{p | action_change: a, supporter_change: s, details: details}}

      {:error, reason} ->
        warn(
          "Skipping supporter detail lookup for org=#{org.name}(#{org.id}): #{inspect(reason)}"
        )

        {:ok, p}
    end
  end

  def lookup_detail(p = %Processing{stage: stage}) when is_nil(stage) do
    {:ok, p}
  end

  @doc """
  Only clear transient personal info if we have reached delivery stage
  """
  def clear_transient(
        %Processing{
          action_change: action_ch,
          supporter_change: supporter_ch,
          stage: :deliver
        } = p
      ) do
    %{
      p
      | action_change: Action.clear_transient_fields(action_ch),
        supporter_change: Supporter.clear_transient_fields(supporter_ch)
    }
  end

  def clear_transient(%Processing{} = p), do: p

  def changed_action(%Processing{action_change: action_ch, supporter_change: supporter_ch}) do
    %{apply_changes(action_ch) | supporter: apply_changes(supporter_ch)}
  end

  @doc """
  This method emits an effect on transition.

  We send whole action data, because a different system will consume it straight
   from rabbitmq.

  """
  @spec emit(Processing, AMQP.Channel | nil) :: :ok | :error
  def emit(p = %Processing{stage: :deliver}, chan) do
    action = changed_action(p)

    publish_for = fn %Proca.Contact{org_id: org_id} ->
      routing = routing_for(action)
      exchange = exchange_for(%Proca.Org{id: org_id}, :deliver)
      data = action_data(action, :deliver, org_id)
      Connection.publish(data, exchange, routing, chan)
    end

    if Enum.all?(action.supporter.contacts, &(publish_for.(&1) == :ok)) do
      :ok
    else
      :error
    end
  end

  def emit(p = %Processing{stage: stage}, chan) when stage != nil do
    action = changed_action(p)
    routing = routing_for(action)
    exchange = exchange_for(action.action_page.org, stage)

    data = action_data(action, stage)

    case Connection.publish(data, exchange, routing, chan) do
      :ok -> :ok
      _ -> :error
    end
  end

  def emit(_procesing, _chan), do: :ok

  @doc """
  Publishes the MTT test event for a freshly committed deliver-stage action.

  Invoked by `Proca.Stage.Action.ack/3` *after* `store!/1` has durably persisted
  `processing_status` to `:delivered`/`:repeat`, so the consumer no longer needs
  to re-check the status (the publish-before-persist race is gone).

  Returns `:ok` whether or not an event is published (non-deliver stages and
  non-testing actions are no-ops); returns `:error` only when the RabbitMQ
  publish itself fails, so the caller can surface it. No message-presence check
  is needed: target `Message` rows are inserted atomically with the action
  (`Proca.Action.Message.put_messages/3`), and the consumer is idempotent on the
  unsent-`Message` set.
  """
  @spec publish_mtt_test_after_store(%Processing{}) :: :ok | :error
  def publish_mtt_test_after_store(%Processing{stage: :deliver} = p) do
    case changed_action(p) do
      %{id: id, testing: true, action_page: %{campaign: %{}}} ->
        queue = Proca.Pipes.Topology.mtt_test_queue()
        warn("MTT test: action #{id} delivered, publishing to #{queue}")
        Connection.publish(%{actionId: id, stage: "deliver", testing: true}, "", queue, nil)

      %{id: id, testing: true} ->
        warn("MTT test: action #{id} is testing but did not match the publish clause (campaign not loaded?)")
        :ok

      _ ->
        :ok
    end
  end

  def publish_mtt_test_after_store(_processing), do: :ok

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

  def exchange_for(org, :deliver) do
    Proca.Pipes.Topology.xn(org, "deliver")
  end

  def store!(%{action_change: a_ch, supporter_change: s_ch}) do
    ch =
      if a_ch.changes == %{} do
        s_ch
      else
        change(a_ch, supporter: s_ch)
      end

    debug(
      "Processing final changeset: #{inspect(a_ch)}+#{inspect(s_ch)}-> #{inspect(ch.changes)}"
    )

    Repo.transaction(fn _r ->
      Repo.update!(ch)
    end)
  end
end
