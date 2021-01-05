defmodule Proca.Pipes.Supervisor do
  @moduledoc """
  Supervisor of Topology processes.
  """
  use DynamicSupervisor
  alias Proca.Pipes
  alias Proca.{Repo, Org}

  def start_link(_arg),
    do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  def init(_arg) do
    init_ret = DynamicSupervisor.init(strategy: :one_for_one)

    Task.start_link(fn ->
      Repo.all(Org) |> Enum.each(&start_child(&1))
    end)

    init_ret
  end

  def start_child(org = %Org{}) do
    DynamicSupervisor.start_child(
      __MODULE__, {Pipes.OrgSupervisor, org})
  end

  def terminate_child(org = %Org{}) do
    Pipes.OrgSupervisor.dispatch(org, fn [{pid, _}] ->
      DynamicSupervisor.terminate_child(__MODULE__, pid)
    end)
  end
end
