defmodule Proca.Pipes.OrgSupervisor do
  alias Proca.Org

  def start_link(org ) do
    Supervisor.start_link(__MODULE__, org, name: process_name(org))
  end

  defp process_name(%Org{id: org_id}) do
    {:via, Registry, {Proca.Pipes.Registry, {__MODULE__, org_id}}}
  end

  def whereis(org = %Org{}) do
    Process.whereis(process_name(org))
  end

  def init(org = %Org{}) do
    children = [
      {Proca.Pipes.Topology, org}
      # Broadway processes
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  def dispatch(%Org{id: org_id}, func) do
    Registry.dispatch(Proca.Pipes.Registry, {__MODULE__, org_id}, func)
  end
end
