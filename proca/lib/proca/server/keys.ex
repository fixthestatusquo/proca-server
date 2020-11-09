defmodule Proca.Server.Keys do
  @moduledoc """
  Stores encryption keys and nonces for each Org id

  State is:
  {my_org_id, fn -> id_to_keys_map, nonce}
  """

  use GenServer
  alias Proca.Repo
  alias Proca.{Org, PublicKey}

  import Logger

  # SERVER INITIALIZATION

  @doc "Start Encrypt server"
  def start_link(nil) do
    {:error, "Please set instance ORG_NAME to specify name"}
  end

  def start_link(org_name) when is_bitstring(org_name) do
    GenServer.start_link(__MODULE__, org_name, name: __MODULE__)
  end

  @impl true
  @doc """
  Initialize Key server with our org name.

  Pass the org name to handle_continue :get_keys to fetch all keys
  """
  def init(org_name) do
    :erlang.process_flag(:sensitive, true)

    info("Start Keys server with #{org_name} instance org")

    case Org.get_by_name(org_name) do
      %Org{id: id} ->
        {
          :ok,
          {id, sensitive_data_wrap(%{}), :crypto.strong_rand_bytes(24)},
          {:continue, :get_keys}
        }

      # {:stop, "Can't find org #{org_name} to be instance org"}
      nil ->
        :ignore
    end
  end

  @impl true
  @doc """
  Fetch all active public keys
  """
  def handle_continue(:get_keys, {ioid, _keys, nonce}) do
    keys = PublicKey.active_keys() |> Repo.all() |> Map.new(fn pk -> {pk.org_id, pk} end)

    case keys[ioid] do
      %PublicKey{public: pub, private: priv} when is_binary(pub) and is_binary(priv) ->
        {
          :noreply,
          {ioid, sensitive_data_wrap(keys), nonce}
        }

      _ ->
        {:stop, "No usable public key for instance org (id: #{ioid})", nil}
    end
  end

  @impl true
  def format_status(reason, [pdict, state]) do
    # XXX ?
    {__MODULE__, pdict}
  end

  # SERVER PART
  @impl true
  def handle_call(
        {:encryption, [to: to_id]},
        from,
        state = {ioid, _k, _n}
      ) do
    handle_call(
      {:encryption, [from: ioid, to: to_id]},
      from,
      state
    )
  end

  def handle_call(
        {:encryption, [from: from_id, to: to_id]},
        _from,
        {ioid, keys, nonce}
      ) do
    k = keys.()
    from_key = k[from_id]
    to_key = k[to_id]

    if is_nil(from_key) or is_nil(to_key) do
      {:reply, :plaintext, {ioid, keys, nonce}}
    else
      {
        :reply,
        {from_key.private, to_key.public, nonce, [from: from_key.id, to: to_key.id]},
        {ioid, keys, increment_nonce(nonce)}
      }
    end
  end

  @impl true
  def handle_cast(
        {:update_key, org_id, keyf},
        {ioid, keys, nonce}
      ) do
    keys2 = keys.() |> Map.put(org_id, keyf.())
    {:noreply, {ioid, sensitive_data_wrap(keys2), nonce}}
  end

  # SERVER API

  def encryption(from_to) do
    GenServer.call(__MODULE__, {:encryption, from_to})
  end

  def update_key(org, key) do
    GenServer.cast(__MODULE__, {:update_key, org.id, sensitive_data_wrap(key)})
    :ok
  end

  # HELPER FUNCTIONS
  @nonce_bits 24 * 8
  @doc "
  Increment nonce by 1. Should be run after every successful encryption.
  "
  defp increment_nonce(nonce) do
    <<x::@nonce_bits>> = nonce
    <<x + 1::@nonce_bits>>
  end

  defp sensitive_data_wrap(data) do
    fn -> data end
  end
end
