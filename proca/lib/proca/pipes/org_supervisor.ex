defmodule Proca.Pipes.OrgSupervisor do
  alias Proca.Org

  def start_link(org = %Org{name: org_name}) do
    Supervisor.start_link(__MODULE__, org, name: process_name(org_name))
  end

  defp process_name(org_name) when is_bitstring(org_name) do
    {:via, Registry, {Proca.Pipes.Registry, "supervisor:" <> org_name}}
  end

  def init(org = %Org{}) do
    children = [
      {Proca.Pipes.Topology, org}
      # Broadway processes
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

end
