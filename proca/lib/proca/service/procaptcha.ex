defmodule Proca.Service.Procaptcha do
  import Logger

  def url do
    Application.get_env(:proca, __MODULE__)[:url]
  end

  def enabled? do
    not is_nil(url())
  end

  def verify(code) do
    case Proca.Service.json_request(nil, url(), form: [response: code]) do
      {:ok, 200, %{"success" => true}} ->
        :ok

      {:ok, 200, %{"success" => false, "reason" => reason}} ->
        {:error, error_message(reason)}

      {:ok, code} ->
        {:error, "Procaptcha returned status #{code}"}

      {:error, error} ->
        error(module: __MODULE__, error: error)
        {:error, "Procaptcha HTTP error"}
    end
  end

  def error_message("expired"), do: "captcha: challenge expired"
  def error_message("already-used"), do: "captcha: challenge already solved"
  def error_message("invalid"), do: "captcha: challenge solution invalid"
  def error_message(_err), do: "captcha: challenge solution validation error"
end
