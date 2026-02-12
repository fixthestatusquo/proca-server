defmodule Proca.Supporter.RejectLink do
  @moduledoc """
  Handles reject-link semantics for supporter confirmation links.

  Reject links are expected to force-reject both supporter and action, and
  revoke DOI when present.
  """

  import Ecto.Changeset
  alias Ecto.Multi
  alias Proca.{Action, Repo, Supporter}
  alias Proca.Server.Notify

  @type notify_fun :: (Supporter.t(), keyword() -> any())

  @spec run(Action.t(), notify_fun()) ::
          {:ok, %{action: Action.t(), supporter: Supporter.t(), email_status_changed?: boolean()}}
          | {:error, term()}
  def run(action = %Action{}, notify_fun \\ &Notify.updated/2) when is_function(notify_fun, 2) do
    # Force reload to avoid stale preloaded associations when reject links are retried.
    supporter = Repo.preload(action, [:supporter], force: true).supporter
    email_status_changed? = supporter.email_status == :double_opt_in

    multi =
      Multi.new()
      |> multi_update_if_changed(:supporter, supporter_changeset(supporter))
      |> multi_update_if_changed(:action, action_changeset(action))

    case Repo.transaction(multi) do
      {:ok, %{action: action2, supporter: supporter2}} ->
        if email_status_changed? do
          notify_fun.(supporter2, id: action2.id)
        end

        {:ok,
         %{action: action2, supporter: supporter2, email_status_changed?: email_status_changed?}}

      {:error, _step, reason, _changes_so_far} ->
        {:error, reason}
    end
  end

  defp multi_update_if_changed(multi, step, changeset = %Ecto.Changeset{}) do
    if map_size(changeset.changes) == 0 do
      Multi.run(multi, step, fn _repo, _changes -> {:ok, changeset.data} end)
    else
      Multi.update(multi, step, changeset)
    end
  end

  defp action_changeset(action = %Action{}) do
    if action.processing_status == :rejected do
      change(action)
    else
      change(action, processing_status: :rejected)
    end
  end

  defp supporter_changeset(supporter = %Supporter{}) do
    status_changeset =
      if supporter.processing_status == :rejected do
        change(supporter)
      else
        change(supporter, processing_status: :rejected)
      end

    if supporter.email_status == :double_opt_in do
      Supporter.changeset(supporter, %{email_status: :unsub})
      |> Ecto.Changeset.merge(status_changeset)
    else
      status_changeset
    end
  end
end
