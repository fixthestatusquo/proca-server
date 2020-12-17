defmodule Proca.Pipes.Topology do
  @moduledoc """
  Topology of processing queue setup in RabbitMQ.

  Each Org has its own Topology server and set of exchanges/queues. Processing
  load and problems are isolated for each org, in way that over

  (previously responsibility of Proca.Server.Plumbing)
  """
  use GenServer
  require Logger
  alias Proca.Org
  alias AMQP.{Channel, Queue, Exchange}
  import AMQP.Basic


  ## API
  def start_link(org = %Org{name: org_name}), do: GenServer.start_link(__MODULE__, org, name: process_name(org_name))

  def stop(%Org{name: org_name}), do: GenServer.stop(process_name(org_name))

  defp process_name(org_name) when is_bitstring(org_name) do
    {:via, Registry, {Proca.Pipes.Registry, "topology:" <> org_name}}
  end

  ## Callbacks
  def init(%Org{id: id, name: org_name}) do
    Logger.info("Starting #{inspect(org_name)}")

    {
      :ok,
      %{
        id: id, name: org_name
      }
    }
  end


  def terminate(reason, %{name: org_name}) do
    Logger.info("Exiting worker: #{org_name} with reason: #{inspect reason}")
  end
end
