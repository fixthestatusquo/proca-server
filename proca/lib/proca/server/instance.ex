defmodule Proca.Server.Instance do
  use GenServer
  alias Proca.Server.Instance

  defstruct [org: nil]

  def start_link(org_name) do
    GenServer.start_link(__MODULE__, org_name, name: __MODULE__)
  end

  def init(org_name) do
    state = case Proca.Org.one([:instance]) do
              nil -> %Instance{}
              instance -> %Instance{org: instance}
            end
    {:ok, state}
  end

  def handle_cast({:update, org}, state) do
    {:noreply, %{state | org: org}}
  end

  def handle_call(:get_org, _from, state = %Instance{org: org}) do
    {:reply, org, state}
  end

  def org() do
    case GenServer.call(__MODULE__, :get_org) do
      {:ok, org} -> org
      _ -> nil
    end
  end

  def update(org) do
    GenServer.cast(__MODULE__, {:update, org})
  end

end
