defmodule Proca.Server.Encrypt do
  use GenServer
  alias Proca.Org

  @impl true
  @doc "When initialized with no org name (for us), then fail"
  def init(nil) do
    {:stop, "Please set ORG_NAME to specify name of my org"}
  end

  @impl true
  @doc "Initialize Encrypt server with our org name.

The server will lookup our org by name, along with its encryption keys (public/private pair).
When less or more then one key pairs are found, fail.
Generate a random 24 bytes for nonce.
Succeed with the state of: public/private key pair for our party, (current) nonce
"
  def init(org_name) do
    case Org.get_by_name(org_name, [:public_keys]) do
      nil ->
        {:stop, "Can't find org #{org_name}. Please create an Org for app and set it as ORG_NAME environment"}
      %Org{public_keys: [], name: org_name} ->
        {:stop, "Missing encryption keys in org #{org_name}"}
      %Org{public_keys: l} when length(l) > 1 ->
        {:stop, "Cannot use more then one our key for encryption"}
      %Org{public_keys: [pk]} ->
        {:ok, {pk, :crypto.strong_rand_bytes(24)}}
    end
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
  @doc "Encrypt plaintext text using recipient public key rcpt_keys.
Calls NaCl box primitive with (text, nonce, our private key, recipien public key).
On failure, returns error from NaCl (the NaCl library fails ugly with FunctionClauseError)
Returns nonce, ciphertext
Increments nonce
"
  def handle_call({:encrypt, rcpt_keys, text}, _from, {my_keys, nonce}) do
    try do
      case Kcl.box(text, nonce, my_keys.private, rcpt_keys.public) do
        {encrypted, _} ->
          {:reply, {encrypted, nonce}, {my_keys, increment_nonce(nonce)}}
      end
    rescue
      e in FunctionClauseError ->
        {:reply,
         {:error, "Bad arguments to Kcl.box - can't call #{e.function}/#{e.arity}"},
         {my_keys, nonce}}
    end
  end

  @impl true
  @doc "Decrypts ciphertext text and it's nonce encrypted by us to recipient.
It is reversing the operation of encryption where we are the sender and other party is recipient.
Of course, we would need to know the recipient's private key.

Calls NaCl unbox primitive with (text, nonce, recipients private key, our public key).
On failure, returns error from NaCl (the NaCl library fails ugly with FunctionClauseError)
Returns cleartext
"
  def handle_call({:decrypt, rcpt_keys, text, nonce}, _from, s = {my_keys, _}) do
    try do
      case Kcl.unbox(text, nonce, rcpt_keys.private,  my_keys.public) do
        {cleartext, _} ->
          {:reply, cleartext, s}
      end
    rescue
      e in FunctionClauseError ->
        {:reply,
         {:error, "Bad arguments to Kcl.box - can't call #{e.function}/#{e.arity}"},
         {my_keys, nonce}}
    end
  end

  def handle_call({:get_keys}, _from, state = {my_keys, _}) do
    {:reply,
     {:ok, my_keys},
     state
    }
  end

  @doc "Start Encrypt server"
  def start_link(org_name) do
    GenServer.start_link(__MODULE__, org_name, name: __MODULE__)
  end

  @doc "Encrypt text using recpieint public key pk"
  def encrypt(%Proca.PublicKey{} = pk, text) do
    GenServer.call(__MODULE__, {:encrypt, pk, text})
  end

  @doc "Decrypt ciphertext with nonce encrypted for party with keys pk"
  def decrypt(%Proca.PublicKey{} = pk, encrypted, nonce) do
    GenServer.call(__MODULE__, {:decrypt, pk, encrypted, nonce})
  end

  @doc "Get public key used by this Encrypt server"
  def get_keys() do
    case GenServer.call(__MODULE__, {:get_keys}) do
      {:ok, pk} -> pk
      _ -> raise "Cannot get key of Encrypt Server"
    end
  end
end
