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
  alias Absinthe.Resolution
  alias Proca.Service
  import ProcaWeb.Helper, only: [msg_ext: 2]

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
        |> Resolution.put_result(
          {:error,
           %{
             message: "Captcha code is required for this API call",
             extensions: %{code: "unauthorized"}
           }}
        )
    end
  end

  def captcha_error(msg, code) do
    msg_ext(msg, code)
    |> Map.put(:path, ["captcha"])
  end

  def verify_hcaptcha(resolution = %{extensions: %{captcha: code}}, secret) do
    case Hcaptcha.verify(code, secret: secret) do
      {:ok, _r} ->
        resolution

      {:error, errors} ->
        errors_as_str = Enum.map(errors, &Atom.to_string/1) |> Enum.join(", ")

        resolution
        |> Resolution.put_result(
          {:error, captcha_error("Captcha code invalid (#{errors_as_str})", "bad_captcha")}
        )
    end
  end

  defp hcaptcha_key() do
    Application.get_env(:proca, __MODULE__)[:hcaptcha_key]
  end

  defp default_service() do
    Application.get_env(:proca, :captcha_service)
  end

  @doc """
  If the hcaptcha or procaptcha is configured for the instance, verify the captcha. Otherwise, noop.
  """
  def verify(resolution = %{extensions: ext = %{captcha: code}}) do
    preferred_service = Map.get(ext, :captcha_service, default_service())

    cond do
      secret = hcaptcha_key() != nil and preferred_service == "hcaptcha" ->
        verify_hcaptcha(resolution, secret)

      Service.Procaptcha.enabled?() and preferred_service == "procaptcha" ->
        case Service.Procaptcha.verify(code) do
          :ok ->
            resolution

          {:error, msg} ->
            resolution
            |> Resolution.put_result({:error, captcha_error(msg, "bad_captcha")})
        end

      true ->
        resolution
    end
  end

  def verify(resolution) do
    resolution
  end
end
