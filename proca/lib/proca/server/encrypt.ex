defmodule Proca.Server.Encrypt do
  @moduledoc """
  Server which holds Home Org encryption keys and current nonce, and performs encryption and decryption of messages to other Orgs using their public keys.
  """
  alias Proca.Repo
  alias Proca.Server.Keys
  alias Proca.{Org, PublicKey}

  import Logger

  def encrypt(%Org{id: id}, text) do
    case Keys.encryption([to: id]) do
      :plaintext -> {text, nil, nil, nil}
      {private, public, nonce, [from: sign_id, to: enc_id]} -> case do_encrypt(text, private, public, nonce) do
                                    {:ok, enc, nonce} -> {enc, nonce, enc_id, sign_id}
                                    error -> error
                                  end
    end
  end

  def encrypt(nil, text) do
    {text, nil, nil, nil}
  end

  defp do_encrypt(text, private, public, nonce) do
    try do
      case Kcl.box(text, nonce, private, public) do
        {encrypted, _} ->
          {:ok, encrypted, nonce}
      end
    rescue
      e in FunctionClauseError ->
         {:error, "Bad arguments to Kcl.box - can't call #{e.function}/#{e.arity}"}
    end
  end
end
