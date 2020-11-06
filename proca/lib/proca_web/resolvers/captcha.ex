defmodule ProcaWeb.Resolvers.Captcha do
  @moduledoc """
  Absinthe middleware to check if captcha code is provided with request.
  Captcha should be provided in extension:
  captcha: key

  Use:
  `middleware Captcha`
  """

  @behaviour Absinthe.Middleware

  import Logger
  alias Proca.Repo
  alias Proca.{Org, Campaign, ActionPage, Users.User, Staffer}
  import Ecto.Query

  def call(resolution, opts) do
    case resolution.extensions do
      %{captcha: code} ->
        verify(resolution, code)
      _a ->
        resolution
        |> Absinthe.Resolution.put_result({:error, %{
                                              message: "Captcha code is required for this API call",
                                              extensions: %{code: "unauthorized"}}})
    end
  end

  def verify(resolution, code) do
    case Application.get_env(:proca, __MODULE__)[:hcaptcha] do
      nil -> resolution
      secret ->
        case Hcaptcha.verify(code, secret: secret) do
          {:ok, _r} -> resolution
          {:error, errors} ->
            errors_as_str = Enum.map(errors, &Atom.to_string/1) |> Enum.join(", ")
            resolution
            |> Absinthe.Resolution.put_result({:error, %{
                                                  message: "Captcha code invalid (#{errors_as_str})",
                                                  extensions: %{code: "bad_request"}
                                               }})
        end
    end
  end
end
