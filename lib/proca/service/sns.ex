defmodule Proca.Service.SNS do
  @moduledoc """
  Verifies messages that AWS SNS posts to our webhooks (SES bounce reports).

  The webhook url is public, and anyone can subscribe it to their own SNS topic,
  so a message is accepted only if it comes from one of our topics and is signed
  with an AWS certificate.
  https://docs.aws.amazon.com/sns/latest/dg/sns-verify-signature-of-message.html

  Allowed topics come from the SES_SNS_TOPIC_ARNS env var, see config/releases.exs.

  ExAws.SNS.verify_message/1 (ex_aws_sns >= 2.3.5) does the same except the topic
  check, but needs Elixir >= 1.15. Replace this with it once we upgrade.
  Do not use older versions, they don't check the certificate url.
  """

  require Record

  @hrl "public_key/include/public_key.hrl"
  Record.defrecordp(:cert, :OTPCertificate, Record.extract(:OTPCertificate, from_lib: @hrl))
  Record.defrecordp(:tbs, :OTPTBSCertificate, Record.extract(:OTPTBSCertificate, from_lib: @hrl))

  Record.defrecordp(
    :key_info,
    :OTPSubjectPublicKeyInfo,
    Record.extract(:OTPSubjectPublicKeyInfo, from_lib: @hrl)
  )

  # fields AWS signs, in this order, for each message type
  @notification_keys ~w(Message MessageId Subject Timestamp TopicArn Type)
  @confirmation_keys ~w(Message MessageId SubscribeURL Timestamp Token TopicArn Type)

  @spec verify(map()) :: :ok | {:error, String.t()}
  def verify(msg) do
    with :ok <- check_topic(msg["TopicArn"]),
         {:ok, keys} <- signed_keys(msg["Type"]),
         {:ok, digest} <- digest(msg["SignatureVersion"]),
         {:ok, signature} <- decode_signature(msg["Signature"]),
         {:ok, public_key} <- public_key(msg["SigningCertURL"]) do
      if :public_key.verify(string_to_sign(msg, keys), digest, signature, public_key) do
        :ok
      else
        {:error, "invalid signature"}
      end
    end
  end

  def topic_arns(), do: Application.get_env(:proca, __MODULE__, [])[:topic_arns] || []

  defp check_topic(arn) do
    if arn in topic_arns(), do: :ok, else: {:error, "topic not allowed: #{inspect(arn)}"}
  end

  defp signed_keys("Notification"), do: {:ok, @notification_keys}
  defp signed_keys("SubscriptionConfirmation"), do: {:ok, @confirmation_keys}
  defp signed_keys("UnsubscribeConfirmation"), do: {:ok, @confirmation_keys}
  defp signed_keys(type), do: {:error, "unknown message type: #{inspect(type)}"}

  defp digest("1"), do: {:ok, :sha}
  defp digest("2"), do: {:ok, :sha256}
  defp digest(v), do: {:error, "unknown signature version: #{inspect(v)}"}

  defp decode_signature(sig) when is_binary(sig) do
    case Base.decode64(sig) do
      {:ok, signature} -> {:ok, signature}
      :error -> {:error, "signature is not base64"}
    end
  end

  defp decode_signature(_), do: {:error, "missing signature"}

  # "Key\nValue\n" for each key present. Optional keys (Subject) are skipped.
  # A non-string value is skipped too, which makes the signature check fail.
  defp string_to_sign(msg, keys) do
    for k <- keys, v = msg[k], is_binary(v), into: "", do: "#{k}\n#{v}\n"
  end

  # certificates rarely change, so each one is downloaded once
  defp public_key(url) do
    with :ok <- check_cert_url(url) do
      case :persistent_term.get({__MODULE__, url}, nil) do
        nil ->
          with {:ok, key} <- fetch_public_key(url) do
            :persistent_term.put({__MODULE__, url}, key)
            {:ok, key}
          end

        key ->
          {:ok, key}
      end
    end
  end

  # otherwise the message could point to the sender's own certificate
  defp check_cert_url(url) when is_binary(url) do
    case URI.parse(url) do
      %URI{scheme: "https", port: 443, host: host, path: path}
      when is_binary(host) and is_binary(path) ->
        if host =~ ~r/\Asns\.[a-z0-9-]+\.amazonaws\.com\z/ and String.ends_with?(path, ".pem") do
          :ok
        else
          {:error, "certificate url not from AWS SNS: #{url}"}
        end

      _ ->
        {:error, "certificate url not from AWS SNS: #{url}"}
    end
  end

  defp check_cert_url(url), do: {:error, "certificate url not from AWS SNS: #{inspect(url)}"}

  defp fetch_public_key(url) do
    case Tesla.get(url) do
      {:ok, %{status: 200, body: pem}} ->
        with [{:Certificate, der, _} | _] <- :public_key.pem_decode(pem),
             cert(tbsCertificate: tbs(subjectPublicKeyInfo: key_info(subjectPublicKey: key))) <-
               :public_key.pkix_decode_cert(der, :otp) do
          {:ok, key}
        else
          _ -> {:error, "cannot read certificate #{url}"}
        end

      other ->
        {:error, "cannot fetch certificate #{url}: #{inspect(other)}"}
    end
  rescue
    _ -> {:error, "cannot read certificate #{url}"}
  end
end
