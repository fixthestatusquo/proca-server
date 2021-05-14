defmodule Proca.Pipes do 
  alias Proca.Pipes

  def enabled?() do 
    Pipes.Connection.is_connected?()
  end
end
