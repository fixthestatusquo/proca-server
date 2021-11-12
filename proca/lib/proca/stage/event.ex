defmodule Proca.Stage.Event do
  alias Proca.{Confirm, Org}
  alias Proca.Pipes.Connection

  def emit(:confirm_created, %Confirm{} = confirm, org_id) when is_number(org_id) do
    routing_key = "confirm_created." <> Atom.to_string(confirm.operation)
    data = Confirm.notify_fields(confirm)
    Connection.publish(exchange_for(org_id), routing_key, data)
  end

  defp exchange_for(org_id) when is_number(org_id) do
    Proca.Pipes.Topology.xn(%Org{id: org_id}, "event")
  end

end
