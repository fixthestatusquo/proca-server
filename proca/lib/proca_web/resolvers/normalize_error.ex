defmodule ProcaWeb.Resolvers.NormalizeError do 
  @behaviour Absinthe.Middleware
  alias ProcaWeb.Error

  @impl true
  def call(resolution, _config) do
      errors =
        resolution.errors
      |> Enum.map(&to_absinthe/1)
      |> List.flatten()

    %{ resolution | errors: errors }
  end

  defp to_absinthe(chset = %Ecto.Changeset{}), do: ProcaWeb.Helper.format_errors(chset)
  defp to_absinthe(lst) when is_list(lst), do: Enum.map(lst, &to_absinthe/1)
  defp to_absinthe(%Error{message: msg, code: nil, context: []}) do 
    %{
      message: msg
    }
  end

  defp to_absinthe(error = %Error{message: nil, code: code}) do
    %{error | message: code}
  end

  defp to_absinthe(%Error{message: msg, code: code, context: []}) do 
    %{
      message: msg, extensions: %{code: code}
    }
  end

  defp to_absinthe(%Error{message: msg, code: code, context: ctx}) do 
    %{
      message: msg,
      extensions: Enum.into(ctx, %{
        code: code
      })
    }
  end

  defp to_absinthe(error), do: error
end
