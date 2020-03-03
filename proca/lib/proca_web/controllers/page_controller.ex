defmodule ProcaWeb.PageController do
  use Phoenix.LiveView

  def render(assigns) do
    ~L"""
    Hello @test
    """
  end

  def mount(_params, _o, socket) do
    {:ok, assign(socket, :test, "world")}
  end
end
