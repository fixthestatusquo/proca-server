defmodule Proca.Server.Instance do
  alias Proca.Server.Instance
  alias Proca.Org

  ## XXX remove this

  def org() do
    Org.one([:instance])
  end
end
