defmodule ProcaWeb.Resolvers.IncludeExtensions do
  @moduledoc """
  Because only context is passed via private settings from Absinthe.Plug, we
  need to pass extensions loaded with ParseExtensions plug inside context. In
  this middleware we move it to Resolution.extensions.
  """

  @behaviour Absinthe.Middleware

  def call(
        resolution = %{
          context: ctx = %{extensions: ext},
          extensions: %{}
        },
        _opts
      )
      when is_map(ext) do
    %{resolution | extensions: ext, context: Map.delete(ctx, :extensions)}
  end

  def call(resolution, _) do
    resolution
  end
end
