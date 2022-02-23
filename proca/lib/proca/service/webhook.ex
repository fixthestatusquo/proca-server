defmodule Proca.Service.Webhook do
  @moduledoc """
  Service configuration of webhook.

  - host - url
  - user - provide for basic auth
  - password - provide only this for Authorization header
  """
  alias Proca.Service

  def push(service = %Service{}, data) do
    Service.json_request(service, service.host, post: data, auth: auth_type(service))
  end

  def auth_type(%{user: u, password: p})
      when is_bitstring(u) and is_bitstring(p),
      do: :basic

  def auth_type(%{password: p}) when is_bitstring(p), do: :header
  def auth_type(_), do: nil
end
