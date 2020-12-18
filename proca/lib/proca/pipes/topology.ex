defmodule Proca.Pipes.Topology do
  @moduledoc """
  Topology of processing queue setup in RabbitMQ.

  Each Org has its own Topology server and set of exchanges/queues. Processing
  load and problems are isolated for each org, in way that over

  (previously responsibility of Proca.Server.Plumbing)

  [action/supporter] RK: campaign.action_type

  x org.N.confirm.supporter    #> =wrk.N.email.optin=
                               #> =cus.N.confirm.supporter

  x org.N.confirm.action       #> =wrk.N.email.confirm
                               #> =cus.N.confirm.action [2]

  x org.N.deliver   [1]   *.mtt > =N.email.mtt=
                          #     > =cus.N.sqs              -> proca-gw
                                > =cus.N.http             -> proca-gw
                                > =cus.N.deliver

                                    DLX:x N.fail fanout> N.fail
                                    DLX:x N.retry direct:$qn-> =$qn=


  Caveats:

  1 - from here a cross-link if it's a partner org? But delivery based on consents, no queue. Also the delivery in such case is just for CRM right ?
  2 - need implemnetation of Confirms - with special confirm code (cc)

  """
  use GenServer
  require Logger
  alias Proca.Org
  alias Proca.Pipes
  alias AMQP.{Channel, Queue, Exchange}
  import AMQP.Basic

  ## API
  def start_link(org = %Org{}), do: GenServer.start_link(__MODULE__, org, name: process_name(org))

  def stop(org = %Org{}), do: GenServer.stop(process_name(org))

  defp process_name(%Org{id: org_id}) do
    {:via, Registry, {Proca.Pipes.Registry, {__MODULE__, org_id}}}
  end

  ## Callbacks
  def init(%Org{id: id, name: org_name}) do
    # Setup queues (without the Broadway ones)
    {:ok, %{org_id: id}}
  end


end
