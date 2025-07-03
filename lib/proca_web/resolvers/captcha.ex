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
           msg_ext(
             "Captcha code is required for this API call",
             "unauthorized"
           )}
        )
    end
  end

  def verify_hcaptcha(resolution = %{extensions: %{captcha: code}}, secret) do
    case Hcaptcha.verify(code, secret: secret) do
      {:ok, _r} ->
        resolution

      {:error, errors} ->
        errors_as_str = Enum.map(errors, &Atom.to_string/1) |> Enum.join(", ")

        resolution
        |> Resolution.put_result(
          {:error, msg_ext("Captcha code invalid (#{errors_as_str})", "bad_captcha")}
        )
    end
  end

  def hcaptcha_key() do
    Application.get_env(:proca, __MODULE__)[:hcaptcha_key]
  end

  def default_service() do
    Application.get_env(:proca, __MODULE__)[:captcha_service]
  end

  def enabled_services() do
    h = if hcaptcha_key(), do: ["hcaptcha"], else: []
    p = if Service.Procaptcha.enabled?(), do: ["procaptcha"], else: []
    h ++ p
  end

  @doc """
  If the hcaptcha or procaptcha is configured for the instance, verify the captcha. Otherwise, noop.
  """
  def verify(resolution = %{extensions: ext = %{captcha: code}}) do
    services = enabled_services()
    s = Map.get(ext, :captcha_service, default_service())

    cond do
      services == [] ->
        resolution

      s not in services ->
        Resolution.put_result(resolution, {:error, msg_ext("not enabled", "bad_arg")})

      s == "hcaptcha" ->
        verify_hcaptcha(resolution, hcaptcha_key())

      s == "procaptcha" ->
        case Service.Procaptcha.verify(code) do
          :ok ->
            resolution

          {:ok, meta} ->
            %{resolution | private: Map.put(resolution.private, :captcha_meta, meta)}

          {:error, msg} ->
            resolution
            |> Resolution.put_result({:error, msg_ext(msg, "bad_captcha")})
        end
    end
  end

  def verify(resolution) do
    resolution
  end
end
