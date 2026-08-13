defmodule Proca.Server.MTTMailer do
  @moduledoc """
  Runtime controls for the MTT RabbitMQ mailer processor.

  Pausing stops per-org `Proca.Stage.MTT` Broadway consumers so messages remain
  in `wrk.N.mtt` for inspection, while schedulers continue publishing.
  Changes apply immediately via `proca rpc` / `scripts/mttmailer` — no restart.
  """

  import Ecto.Query

  alias Proca.{Org, Repo}
  alias Proca.Pipes.OrgSupervisor
  alias Proca.Server.MTT
  alias Proca.Stage.MTT, as: MTTStage

  @paused_key {__MODULE__, :paused}

  def pause do
    set_paused(true)
    stop_processors()
    :ok
  end

  def start do
    set_paused(false)
    start_processors()
    :ok
  end

  def set_paused(flag) when is_boolean(flag) do
    :persistent_term.put(@paused_key, flag)
    :ok
  end

  def paused?, do: :persistent_term.get(@paused_key, false)

  def status do
    %{
      paused: paused?(),
      mode: MTT.mode(),
      max_messages_per_cycle: max_messages_per_cycle(),
      retry_limit: retry_limit()
    }
  end

  def set_max_messages_per_cycle(n) when is_integer(n) and n >= 1 do
    current = Application.get_env(:proca, Proca.Server.MTTWorker, [])

    Application.put_env(
      :proca,
      Proca.Server.MTTWorker,
      Keyword.put(current, :max_messages_per_cycle, n)
    )

    :ok
  end

  def set_max_messages_per_cycle(_), do: {:error, :invalid_max_messages}

  def max_messages_per_cycle do
    Application.get_env(:proca, Proca.Server.MTTWorker, [])
    |> Keyword.get(:max_messages_per_cycle, 99)
  end

  def retry_limit do
    Application.get_env(:proca, MTT, [])
    |> Keyword.get(:retry_limit)
  end

  defp stop_processors do
    Enum.each(list_orgs(), fn org ->
      case OrgSupervisor.whereis(org) do
        nil ->
          :ok

        pid ->
          case Supervisor.terminate_child(pid, MTTStage) do
            :ok -> Supervisor.delete_child(pid, MTTStage)
            {:error, :not_found} -> :ok
            _ -> :ok
          end
      end
    end)
  end

  defp start_processors do
    Enum.each(list_orgs_with_backends(), fn org ->
      if MTTStage.start_for?(org) do
        case OrgSupervisor.whereis(org) do
          nil ->
            :ok

          pid ->
            case Supervisor.start_child(pid, {MTTStage, org}) do
              {:ok, _} ->
                :ok

              {:error, {:already_started, _}} ->
                :ok

              {:error, :already_present} ->
                Supervisor.restart_child(pid, MTTStage)
                :ok

              _ ->
                :ok
            end
        end
      end
    end)
  end

  defp list_orgs do
    Repo.all(Org)
  rescue
    _ -> []
  end

  defp list_orgs_with_backends do
    Repo.all(from(o in Org, preload: [:email_backend, :campaigns]))
  rescue
    _ -> []
  end
end
