defmodule Proca.Pipes do 
  alias Proca.Pipes

  def enabled?() do 
    Pipes.Connection.is_connected?()
  end

  def queue_url() do
   Application.get_env(:proca, Proca.Pipes)[:url]
  end
end
