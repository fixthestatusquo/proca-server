
defmodule Proca.Service.Preview.OrgStorage do
  use Agent
  @behaviour Swoosh.Adapters.Local.Storage

  alias Swoosh.Email

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def push(email) do
    org_name = email.private[:org_name] || :default
    Agent.update(__MODULE__, &Map.update(&1, org_name, [email], fn emails -> [email | emails] end))
    email
  end

  def get(org_name) do
    Agent.get(__MODULE__, &Map.get(&1, org_name, []))
  end

  def get_all() do
    Agent.get(__MODULE__, & &1)
  end

  def delete_all() do
    Agent.update(__MODULE__, fn _ -> %{} end)
  end

  def delete(org_name) do
    Agent.update(__MODULE__, &Map.delete(&1, org_name))
  end
end
