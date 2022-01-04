defmodule Proca.Pipes.Supervisor do
  @moduledoc """
  Supervisor of Topology processes and Processing Workers.

  The processes involved are:

  Pipes.Registry  - a process registry for all Pipes-related processes

  Pipes.Connection - a process managing Queue connection

  Pipes.Supervisor - supervises the whole processing hierarchy
   |
   |--- OrgSupervisor(org_id) --- Topology - manage queue/exchange setup for org_id
   |                           `- Worker1
   |                           `- Worker2
   |--- OrgSupervisor(org_id2) -- Topology - for org_id2
   .
   .

  """
  use DynamicSupervisor
  alias Proca.Pipes
  alias Proca.{Repo, Org}
  import Logger

  def start_link(_arg),
    do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(org = %Org{}) do
    debug("Starting Pipes OrgSupervisor for #{org.name} id #{org.id}")

    DynamicSupervisor.start_child(
      __MODULE__,
      {Pipes.OrgSupervisor, org}
    )
  end

  def terminate_child(org = %Org{}) do
    debug("Stopping Pipes OrgSupervisor for #{org.name} id #{org.id}")

    Pipes.OrgSupervisor.dispatch(org, fn [{pid, _}] ->
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end)
  end

  @doc "Restart org pipes topology if configuration chanaged"
  def reload_child(org = %Org{}) do
    case Pipes.Topology.whereis(org) do
      nil ->
        info("Org processing starting for #{org.name} (#{org.id})")
        start_child(org)

      pid ->
        if GenServer.call(pid, {:configuration_change?, org}) do
          info("Org processing configuration changed for #{org.name} (#{org.id})")
          terminate_child(org)
          start_child(org)
        end
    end
  end

  def handle_connected() do
    # run after the connection is made but synchronously, in which case we would have deadlock
    # waiting for OrgSupervisor->Topology->Connection.connection()
    Task.start_link(fn ->
      Repo.all(Org) |> Enum.each(&start_child(&1))
    end)
  end

  def handle_disconnected() do
    Repo.all(Org) |> Enum.each(&terminate_child(&1))
  end
end
