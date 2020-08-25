defmodule Proca.Server.Encrypt do
  @moduledoc """
  Server which holds Home Org encryption keys and current nonce, and performs encryption and decryption of messages to other Orgs using their public keys.
  """

  use GenServer
  alias Proca.Repo
  alias Proca.{Org, PublicKey}

  import Logger

  @impl true
  @doc "When initialized with no org name (for us), then fail"
  def init(nil) do
    {:stop, "Please set ORG_NAME to specify name of my org"}
  end

  @impl true
  @doc """
  Initialize Encrypt server with our org name.

  The server will lookup our org by name, along with its encryption keys (public/private pair).
  When less or more then one key pairs are found, fail.
  Generate a random 24 bytes for nonce.
  Succeed with the state of: public/private key pair for our party, (current) nonce
  """
  def init(org_name) do
    {:ok, org_name, {:continue, :get_keys}}
  end

  @impl true
  @doc """
  Fetch the instance org based on org_name passed to this server. Stop server if such org does not exist.
  Fetch an active key for this organisation, and if it is not found or does not have a private part present, generate it.
  """
  def handle_continue(:get_keys, org_name) do
    with instance_org when not is_nil(instance_org) <- Org.get_by_name(org_name),
         keys <- PublicKey.active_keys() |> Repo.all() |> Map.new(fn pk -> {pk.org_id, pk} end),
           my_keys <- ensure_encryption_key(keys[instance_org.id], instance_org)
      do
      {:noreply, {my_keys, :crypto.strong_rand_bytes(24), keys}}
      else
        nil -> {:stop, "Can't find org #{org_name}. Instance org needs to exist."}
    end
  end

  defp ensure_encryption_key(pk, org) when is_nil(pk) do
    Logger.warn("Generate an instance key, because it is null")
    {:ok, pk} = PublicKey.build_for(org) |> Repo.insert()
    pk
  end

  defp ensure_encryption_key(%PublicKey{private: prv}, org) when is_nil(prv) do
    Logger.warn("Generate an instance key, because it has no private key")
    {:ok, pk} = PublicKey.build_for(org) |> Repo.insert()
    pk
  end

  defp ensure_encryption_key(pk, _org) do
    Logger.warn("Instance key name #{pk.name}")
    pk
  end

  @nonce_bits 24*8
  @doc "
Increment nonce by 1. Should be run after every successful encryption.
"
  def increment_nonce(nonce) do
    << x :: @nonce_bits >> = nonce
    << x + 1 :: @nonce_bits >>
  end

  @impl true
  def handle_call({:encrypt, %Org{id: id}, text}, from, state = {_, _, keys}) do
    pk = keys[id]
    handle_call({:encrypt, pk, text}, from, state)
  end

  @impl true
  def handle_call({:encrypt, %PublicKey{id: pub_id, public: public}, text}, _from, {my_keys, nonce, keys}) do
    try do
      case Kcl.box(text, nonce, my_keys.private, public) do
        {encrypted, _} ->
          {:reply, {encrypted, nonce, pub_id, my_keys.id}, {my_keys, increment_nonce(nonce), keys}}
      end
    rescue
      e in FunctionClauseError ->
        {:reply,
         {:error, "Bad arguments to Kcl.box - can't call #{e.function}/#{e.arity}"},
         {my_keys, nonce, keys}}
    end
  end

  @impl true
  def handle_call({:encrypt, pk, text}, _from, state) when is_nil(pk) do
    {:reply, {text, nil, nil, nil}, state}
  end

  @impl true
  def handle_call({:decrypt, %Org{id: id}, text, text_nonce}, from, state = {_, _, keys}) do
    pk = keys[id]
    handle_call({:decrypt, pk, state}, from, state)
  end

  @impl true
  def handle_call({:decrypt, %PublicKey{public: sender_pub}, text, text_nonce}, _from, s = {my_keys, nonce, keys}) do
    try do
      case Kcl.unbox(text, text_nonce, my_keys.private, sender_pub) do
        {cleartext, _} ->
          {:reply, cleartext, s}
      end
    rescue
      e in FunctionClauseError ->
        {:reply,
         {:error, "Bad arguments to Kcl.box - can't call #{e.function}/#{e.arity}"},
         s}
    end
  end

  @impl true
  def handle_call({:get_keys}, _from, state = {my_keys, _}) do
    {:reply,
     {:ok, my_keys},
     state
    }
  end

  @impl true
  def handle_cast({:update_key, org_id, key}, {my_keys, nonce, keys}) do
    {:noreply, {my_keys, nonce, Map.put(keys, org_id, key)}}
  end

  @doc "Start Encrypt server"
  def start_link(org_name) do
    GenServer.start_link(__MODULE__, org_name, name: __MODULE__)
  end

  @doc """
  Encrypt plaintext text using recipient public key pk

  Calls NaCl box primitive with (text, nonce, our private key, recipien public key).
  On failure, returns error from NaCl (the NaCl library fails ugly with FunctionClauseError)
  Returns nonce, ciphertext
  Increments nonce
  """
  @spec encrypt(Org | PublicKey, binary()) :: {binary(), binary(), integer()} | {:error, String.t()}
  def encrypt(pk_or_org, text) do
    GenServer.call(__MODULE__, {:encrypt, pk_or_org, text})
  end

  @doc """
  Decrypts ciphertext text and it's nonce encrypted by us to recipient.

  It is reversing the operation of encryption where we are the sender and other party is recipient.
  Of course, we would need to know the recipient's private key.

  Calls NaCl unbox primitive with (text, nonce, recipients private key, our public key).
  On failure, returns error from NaCl (the NaCl library fails ugly with FunctionClauseError)
  Returns cleartext
  """
  @spec decrypt(Org | PublicKey, binary(), binary()) :: binary() | {:error, String.t()}
  def decrypt(pk_or_org, encrypted, nonce) do 
    GenServer.call(__MODULE__, {:decrypt, pk_or_org, encrypted, nonce})
  end

  def update_key(org, key) do
    GenServer.cast(__MODULE__, {:update_key, org.id, key})
    :ok
  end

  @doc "Get public key used by this Encrypt server"
  def get_keys() do
    case GenServer.call(__MODULE__, {:get_keys}) do
      {:ok, pk} -> pk
      _ -> raise "Cannot get key of Encrypt Server"
    end
  end
end
