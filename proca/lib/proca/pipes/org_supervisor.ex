defmodule Proca.Pipes.OrgSupervisor do
  alias Proca.Org

  def start_link(org) do
    Supervisor.start_link(__MODULE__, org, name: process_name(org))
  end

  defp process_name(%Org{id: org_id}) do
    {:via, Registry, {Proca.Pipes.Registry, {__MODULE__, org_id}}}
  end

  def whereis(o = %Org{}) do
    {:via, Registry, {reg, nam}} = process_name(o)
    case Registry.lookup(reg, nam) do
      [{pid, _}] -> pid
      [] -> nil
    end
  end

  def child_spec(org = %Org{}) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [org]},
      restart: :transient,
      type: :supervisor
    }
  end

  # @impl true
  def init(org = %Org{}) do
    topology = {Proca.Pipes.Topology, org}

    workers = [
      Proca.Stage.ThankYou,
      Proca.Stage.SQS,
    ]
    |> Enum.filter(fn mod -> apply(mod, :start_for?, [org]) end)
    |> Enum.map(fn mod -> {mod, org} end)

    Supervisor.init([topology | workers], strategy: :rest_for_one)
  end

  def dispatch(o = %Org{}, func) do
    {:via, Registry, {reg, nam}} = process_name(o)
    Registry.dispatch(reg, nam, func)
  end
end
