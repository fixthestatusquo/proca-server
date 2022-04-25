defmodule Proca.Server.Jwks do
  @moduledoc """
  Because JWT authentication requires a JWKS certificate retrieved from an url
  (from the token issuer), this server holds/caches this information.

  This server will try to fetch a new key when asked for nonexistent key id.
  XXX protect against forcing this server to retry getting a fake kid
  """
  use GenServer
  import Logger

  def start_link(keys_url) do
    GenServer.start_link(__MODULE__, keys_url, name: __MODULE__)
  end

  def init(keys_url) do
    if keys_url == nil do
      :ignore
    else
      {:ok, {%{}, keys_url}, {:continue, :get_keys}}
    end
  end

  def handle_continue(:get_keys, {%{}, url}) do
    {:noreply,
     {
       get_keys(url),
       url
     }}
  end

  def get_keys("file://" <> path = _url) do
    try do
      jwks_to_keys(File.read!(path))
    rescue
      e in File.Error ->
        error("Cannot #{e.action} #{e.path}: #{e.reason}")
        %{}
    end
  end

  def get_keys(url) do
    with {:ok, 200, _, ref} <- :hackney.get(url),
         {:ok, body} <- :hackney.body(ref) do
      jwks_to_keys(body)
    else
      _ -> %{}
    end
  end

  def jwks_to_keys(jwks) do
    jwks = Jason.decode!(jwks)

    case Map.get(jwks, "keys") do
      keys when is_list(keys) ->
        keys
        |> Enum.map(fn key -> {key["kid"], key} end)
        |> Map.new()

      _ ->
        %{}
    end
  end

  def handle_call({:key, kid}, _from, {keys, url}) do
    case Map.get(keys, kid, nil) do
      nil ->
        new_keys = get_keys(url)
        key = Map.get(new_keys, kid)
        {:reply, key, {Map.merge(keys, new_keys), url}}

      key ->
        {
          :reply,
          key,
          {keys, url}
        }
    end
  end

  def key(kid) do
    GenServer.call(__MODULE__, {:key, kid})
  end
end
