defmodule Proca.Server.Instance do
  alias Proca.Org

  ## XXX remove this

  def org() do
    Org.one([:instance])
  end
end
