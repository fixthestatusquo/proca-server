defmodule Proca.Stage.UnprocessedActions do
  @moduledoc """

  Stage which produces unproduced actions, which might be unprocessed because of
  no queue was available, or because processing failed.

  We process the actions one by one synchronously because the processing will
  update the associated supporter.

  We use thre intervals to control processing of old actions:

  - @time_margin - (1 minute default) - do not process actions more recent then
    one minute - they might be actually still processed by async-after-add processing.


  - @sweep_interval (1 second default) - how long to wait between processing of all history (we don't want to start from beginning straight away)

  """
  import Proca.Repo
  import Ecto.Query, only: [from: 2]
  use GenStage

  # Seconds
  @sweep_interval 60 * 10
  @time_margin 60 * 2

  @impl true
  def init(opts) do
    s = %{
      demand: 0,
      last_id: 0,
      sweep_interval: opts[:sweep_interval] || @sweep_interval,
      sweep_sleep: false,
      time_margin: opts[:time_margin] || @time_margin
    }

    {:producer, s}
  end

  @doc """
  Poll for actions and update demand accordingly
  """
  def return_actions(
        %{demand: demand, last_id: last_id, time_margin: margin, sweep_interval: sweep} = st
      ) do
    actions = unprocessed_actions(demand, last_id, margin)

    actions_count = length(actions)

    st =
      if demand > actions_count and not st.sweep_sleep do
        # Special case: we finished the sweep, lets schedule another one
        # We check the sweep_sleep as GenStage might ask us one or two times at the end of actions.
        Process.send_after(self(), :restart, sweep * 1_000)
        %{st | sweep_sleep: true}
      else
        st
      end

    last_id =
      case List.last(actions) do
        %{id: id} -> id
        nil -> last_id
      end

    {:noreply, actions, %{st | demand: demand - actions_count, last_id: last_id}}
  end

  @impl true
  def handle_demand(demand, %{demand: d} = st) do
    st = %{st | demand: d + demand}

    return_actions(st)
  end

  @impl true
  def handle_info(:restart, st) do
    st = %{st | last_id: 0, sweep_sleep: false}

    return_actions(st)
  end

  def unprocessed_actions(0, _), do: []

  def unprocessed_actions(demand, last_id, margin) do
    from(a in Proca.Action,
      join: s in Proca.Supporter,
      on: a.supporter_id == s.id,
      where:
        a.id > ^last_id and
          a.inserted_at < ago(^margin, "second") and
          ((a.processing_status == :new and s.processing_status == :new) or
             (a.processing_status == :new and s.processing_status == :accepted) or
             (a.processing_status == :accepted and s.processing_status == :accepted)),
      limit: ^demand,
      order_by: [asc: a.id]
    )
    |> all()
  end
end

# defmodule TestConsumer do
#   use GenStage

#   @impl true
#   def init(_), do: {:consumer, []}

#   @impl true
#   def handle_events(ev, _, st) do
#     {:noreply, [], st}
#   end
# end
