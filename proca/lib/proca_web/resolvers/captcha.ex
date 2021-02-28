defmodule ProcaWeb.Resolvers.Captcha do
  @moduledoc """
  Absinthe middleware to check if captcha code is provided with request.
  Captcha should be provided in extension:
  captcha: key

  Use:
  `middleware Captcha`

  `middleware Captcha, defer: true` - if you want to verify the captcha inside processing.
  """

  @doc """
  Make sure the captcha extension is provided for the request.

  If defer: true, do not actually verify the captcha yet. Let the resolver call
  verify() and check if the resolution is failed.
  """
  @behaviour Absinthe.Middleware
  def call(resolution, opts) do
    case resolution.extensions do
      %{captcha: _code} ->
        case Keyword.get(opts, :defer, false) do
          true -> resolution
          false -> verify(resolution)
        end

      _a ->
        resolution
        |> Absinthe.Resolution.put_result(
          {:error,
           %{
             message: "Captcha code is required for this API call",
             extensions: %{code: "unauthorized"}
           }}
        )
    end
  end


  @doc """
  If the hcaptcha is configured for the instance, verify the captcha. Otherwise, noop.
  """

  def verify(resolution = %{extensions: %{captcha: code}}) do
    case Application.get_env(:proca, __MODULE__)[:hcaptcha] do
      nil ->
        resolution

      secret ->
        case Hcaptcha.verify(code, secret: secret) do
          {:ok, _r} ->
            resolution

          {:error, errors} ->
            errors_as_str = Enum.map(errors, &Atom.to_string/1) |> Enum.join(", ")

            resolution
            |> Absinthe.Resolution.put_result(
              {:error,
               %{
                 message: "Captcha code invalid (#{errors_as_str})",
                 extensions: %{code: "bad_captcha"}
               }}
            )
        end
    end
  end

  def verify(resolution) do
    resolution
  end
end
