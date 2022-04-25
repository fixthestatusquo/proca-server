defmodule Proca.Service.Webhook do
  @moduledoc """
  Service configuration of webhook.

  - host - url
  - user - provide for basic auth
  - password - provide only this for Authorization header
  """
  alias Proca.Service

  def push(service = %Service{}, data) do
    payload = Jason.encode!(data)
    url = merge_url_tags(service.host, data)

    Service.json_request(service, url, post: payload, auth: auth_type(service))
  end

  @doc """
  Merge tags like: {{foo}} by value from data["foo"]
  """
  def merge_url_tags(url, data) do
    String.replace(url, ~r/{{\w_}}/, fn s ->
      case Map.get(data, s) do
        r when is_bitstring(r) -> r
        r when is_integer(r) -> Integer.to_string(r)
        _ -> s
      end
    end)
  end

  def auth_type(%{user: u, password: p})
      when is_bitstring(u) and is_bitstring(p),
      do: :basic

  def auth_type(%{password: p}) when is_bitstring(p), do: :header
  def auth_type(_), do: nil
end
