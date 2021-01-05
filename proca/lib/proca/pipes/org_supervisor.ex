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

    has_email_services = (not is_nil(org.email_backend_id)) and (not is_nil(org.template_backend_id))

    workers = [
      {
        Proca.Stage.ThankYou, has_email_services
      },
      {
        Proca.Stage.SQS, org.system_sqs_deliver
      }
    ]
    |> Enum.filter(fn {_, enabled?} -> enabled? end)
    |> Enum.map(fn {mod, _} -> {mod, org} end)

    Supervisor.init([topology | workers], strategy: :rest_for_one)
  end

  def dispatch(o = %Org{}, func) do
    {:via, Registry, {reg, nam}} = process_name(o)
    Registry.dispatch(reg, nam, func)
  end
end
