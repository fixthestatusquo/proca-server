defmodule Proca.SNSSigner do
  @moduledoc """
  Signs SNS messages like AWS does, with a test certificate, for tests of
  Proca.Service.SNS and the /webhook/ses endpoint.
  """

  @signed_keys ~w(Message MessageId Subject SubscribeURL Timestamp Token TopicArn Type)

  @doc "A self signed certificate as PEM, and its private key"
  def generate_cert() do
    %{cert: der, key: key} =
      :public_key.pkix_test_root_cert(~c"sns test", [{:key, {:rsa, 2048, 65537}}])

    %{pem: :public_key.pem_encode([{:Certificate, der, :not_encrypted}]), key: key}
  end

  @doc "Adds Signature: \"Key\\nValue\\n\" for the signed keys present, sorted"
  def sign(msg, key) do
    text =
      @signed_keys
      |> Enum.filter(&Map.has_key?(msg, &1))
      |> Enum.map_join(fn k -> "#{k}\n#{msg[k]}\n" end)

    digest = if msg["SignatureVersion"] == "2", do: :sha256, else: :sha
    Map.put(msg, "Signature", Base.encode64(:public_key.sign(text, digest, key)))
  end
end
