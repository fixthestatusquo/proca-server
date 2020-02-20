defmodule Proca.Server.Encrypt do
  use GenServer
  import Ecto.Query
  alias Proca.Org

  def start_link(org_id) do
    GenServer.start_link(__MODULE__, org_id, name: __MODULE__)
  end

  @impl true
  def init(org_id) do
    case from(o in Org, preload: [:public_keys]) |> Proca.Repo.get(org_id) do
      nil ->
        {:stop, "Missing Org for my party in encryption. Please create an Org for app and set it as ORG_ID environment val"}
      %Org{public_keys: [], name: org_name} ->
        {:stop, "Missing encryption keys in org #{org_name}"}
      %Org{public_keys: l} when length(l) > 1 ->
        {:stop, "Cannot use more then one our key for encryption"}
      %Org{public_keys: [pk]} ->
        {:ok, {pk, :crypto.strong_rand_bytes(24)}}
    end
  end

  @nonce_bits 24*8
  def increment_nonce(nonce) do
    << x :: @nonce_bits >> = nonce
    << x + 1 :: @nonce_bits >>
  end

  @impl true
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


  def encrypt(%Proca.PublicKey{} = pk, text) do
    GenServer.call(__MODULE__, {:encrypt, pk, text})
  end

  def decrypt(%Proca.PublicKey{} = pk, encrypted, nonce) do
    GenServer.call(__MODULE__, {:decrypt, pk, encrypted, nonce})
  end
end
