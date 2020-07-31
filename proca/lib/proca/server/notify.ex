defmodule Proca.Server.Notify do
  @spec action_created(Action, boolean()) :: :ok
  def action_created(action, created_supporter) do
    increment_counter(action, created_supporter)
    process_action(action)
    :ok
  end

  defp process_action(action) do
    Proca.Server.Processing.process_async(action)
  end

  defp increment_counter(%{campaign_id: cid, action_type: atype}, new_supporter) do
    Proca.Server.Stats.increment(cid, atype, new_supporter)
  end
end
