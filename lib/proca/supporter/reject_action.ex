defmodule Proca.Supporter.RejectAction do
  @moduledoc """
  Rejects an action and its supporter with optional email status updates.
  """

  import Ecto.Changeset
  alias Ecto.Multi
  alias Proca.{Action, Repo, Supporter}
  alias Proca.Server.Notify

  @type notify_fun :: (Supporter.t(), keyword() -> any())
  @type email_status_opt :: :revoke_doi | atom() | nil
  @type run_opt ::
          {:email_status, email_status_opt()}
          | {:notify, boolean()}
          | {:notify_fun, notify_fun()}
  @type run_opts :: [run_opt()]

  @spec run(Action.t(), run_opts()) ::
          {:ok, %{action: Action.t(), supporter: Supporter.t(), email_status_changed?: boolean()}}
          | {:error, term()}
  def run(action = %Action{}, opts \\ []) when is_list(opts) do
    notify? = Keyword.get(opts, :notify, true)
    notify_fun = Keyword.get(opts, :notify_fun, &Notify.updated/2)
    email_status = Keyword.get(opts, :email_status, :revoke_doi)

    if not is_boolean(notify?), do: raise(ArgumentError, "notify must be boolean")
    if not is_function(notify_fun, 2), do: raise(ArgumentError, "notify_fun must have arity 2")

    # Force reload to avoid stale preloaded associations when retries happen.
    action = Repo.preload(action, [:supporter], force: true)

    case action.supporter do
      supporter = %Supporter{} ->
        email_status_changed? = email_status_changed?(supporter, email_status)

        multi =
          Multi.new()
          |> multi_update_if_changed(:supporter, supporter_changeset(supporter, email_status))
          |> multi_update_if_changed(:action, action_changeset(action))

        case Repo.transaction(multi) do
          {:ok, %{action: action2, supporter: supporter2}} ->
            if notify? and email_status_changed? do
              notify_fun.(supporter2, id: action2.id)
            end

            {:ok,
             %{
               action: action2,
               supporter: supporter2,
               email_status_changed?: email_status_changed?
             }}

          {:error, _step, reason, _changes_so_far} ->
            {:error, reason}
        end

      nil ->
        {:error, :supporter_not_found}
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

  defp supporter_changeset(supporter = %Supporter{}, email_status) do
    status_changeset =
      if supporter.processing_status == :rejected do
        change(supporter)
      else
        change(supporter, processing_status: :rejected)
      end

    case email_status_changeset(supporter, email_status) do
      nil ->
        status_changeset

      email_changeset ->
        Ecto.Changeset.merge(email_changeset, status_changeset)
    end
  end

  defp email_status_changeset(%Supporter{email_status: :double_opt_in} = supporter, :revoke_doi) do
    Supporter.changeset(supporter, %{email_status: :unsub})
  end

  defp email_status_changeset(%Supporter{}, :revoke_doi), do: nil
  defp email_status_changeset(%Supporter{}, nil), do: nil

  defp email_status_changeset(%Supporter{email_status: email_status}, email_status), do: nil

  defp email_status_changeset(%Supporter{} = supporter, email_status)
       when is_atom(email_status) do
    Supporter.changeset(supporter, %{email_status: email_status})
  end

  defp email_status_changeset(%Supporter{}, other) do
    raise ArgumentError,
          "email_status must be an atom, :revoke_doi, or nil, got: #{inspect(other)}"
  end

  defp email_status_changed?(%Supporter{email_status: :double_opt_in}, :revoke_doi), do: true
  defp email_status_changed?(%Supporter{}, :revoke_doi), do: false
  defp email_status_changed?(%Supporter{}, nil), do: false
  defp email_status_changed?(%Supporter{email_status: email_status}, email_status), do: false
  defp email_status_changed?(%Supporter{}, email_status) when is_atom(email_status), do: true

  defp email_status_changed?(%Supporter{}, other) do
    raise ArgumentError,
          "email_status must be an atom, :revoke_doi, or nil, got: #{inspect(other)}"
  end
end
