defmodule Proca.Service.SNSTest do
  # changes app env and the tesla adapter
  use ExUnit.Case, async: false

  alias Proca.Service.SNS
  import Proca.SNSSigner, only: [sign: 2]

  @topic "arn:aws:sns:eu-west-3:123456789012:proca-ses-events"

  setup_all do
    Proca.SNSSigner.generate_cert()
  end

  setup %{pem: pem} do
    adapter = Application.get_env(:tesla, :adapter)
    config = Application.get_env(:proca, SNS)
    Application.put_env(:tesla, :adapter, Tesla.Mock)
    Application.put_env(:proca, SNS, topic_arns: [@topic])

    on_exit(fn ->
      Application.put_env(:tesla, :adapter, adapter)
      Application.put_env(:proca, SNS, config)
    end)

    Tesla.Mock.mock(fn %{method: :get} -> %Tesla.Env{status: 200, body: pem} end)

    # certificates are cached by url, a new url makes each test download it
    %{
      cert_url:
        "https://sns.eu-west-3.amazonaws.com/cert-#{System.unique_integer([:positive])}.pem"
    }
  end

  defp notification(cert_url) do
    %{
      "Type" => "Notification",
      "MessageId" => "3485ca5a-6778-5aed-ab89-a9018022fee3",
      "TopicArn" => @topic,
      "Subject" => "Amazon SES Email Event Notification",
      "Message" => ~s({"eventType":"Bounce"}),
      "Timestamp" => "2026-10-28T12:05:46.033Z",
      "SignatureVersion" => "1",
      "SigningCertURL" => cert_url
    }
  end

  defp confirmation(cert_url) do
    %{
      "Type" => "SubscriptionConfirmation",
      "MessageId" => "165545c9-2a5c-472c-8df2-7ff2be2b3b1b",
      "Token" => "2336412f37",
      "TopicArn" => @topic,
      "Message" => "You have chosen to subscribe to the topic",
      "SubscribeURL" => "https://sns.eu-west-3.amazonaws.com/?Action=ConfirmSubscription",
      "Timestamp" => "2026-10-28T12:00:00.000Z",
      "SignatureVersion" => "1",
      "SigningCertURL" => cert_url
    }
  end

  test "accepts a signed notification", %{key: key, cert_url: url} do
    assert :ok = notification(url) |> sign(key) |> SNS.verify()
  end

  test "accepts a notification without subject", %{key: key, cert_url: url} do
    assert :ok = notification(url) |> Map.delete("Subject") |> sign(key) |> SNS.verify()
  end

  test "accepts signature version 2 (sha256)", %{key: key, cert_url: url} do
    assert :ok =
             notification(url) |> Map.put("SignatureVersion", "2") |> sign(key) |> SNS.verify()
  end

  test "accepts a signed subscription confirmation", %{key: key, cert_url: url} do
    assert :ok = confirmation(url) |> sign(key) |> SNS.verify()
  end

  test "rejects a changed message", %{key: key, cert_url: url} do
    msg = notification(url) |> sign(key) |> Map.put("Message", ~s({"eventType":"Complaint"}))
    assert {:error, "invalid signature"} = SNS.verify(msg)
  end

  test "rejects a message signed with another key", %{cert_url: url} do
    other_key = :public_key.generate_key({:rsa, 2048, 65537})
    assert {:error, "invalid signature"} = notification(url) |> sign(other_key) |> SNS.verify()
  end

  test "rejects topics not in the allowlist", %{key: key, cert_url: url} do
    other = "arn:aws:sns:eu-west-3:666:other"
    msg = notification(url) |> Map.put("TopicArn", other) |> sign(key)
    assert {:error, {:topic_not_allowed, ^other}} = SNS.verify(msg)
  end

  test "rejects everything when no topics are configured", %{key: key, cert_url: url} do
    Application.put_env(:proca, SNS, topic_arns: [])
    assert {:error, {:topic_not_allowed, @topic}} = notification(url) |> sign(key) |> SNS.verify()
  end

  test "reports topic_not_allowed only for messages signed by AWS", %{cert_url: url} do
    other_key = :public_key.generate_key({:rsa, 2048, 65537})
    msg = notification(url) |> Map.put("TopicArn", "arn:aws:sns:eu-west-3:666:other")
    assert {:error, "invalid signature"} = msg |> sign(other_key) |> SNS.verify()
  end

  test "rejects certificates not hosted by AWS SNS", %{key: key} do
    for url <- [
          "https://evil.example.com/cert.pem",
          "https://sns.eu-west-3.amazonaws.com.evil.example.com/cert.pem",
          "https://sns.eu-west-3.amazonaws.com@evil.example.com/cert.pem",
          "http://sns.eu-west-3.amazonaws.com/cert.pem",
          "https://sns.eu-west-3.amazonaws.com/cert.txt",
          nil
        ] do
      assert {:error, "certificate url not from AWS SNS" <> _} =
               notification(url) |> sign(key) |> SNS.verify()
    end
  end

  test "rejects a signature that is not base64", %{cert_url: url} do
    msg = notification(url) |> Map.put("Signature", "not base64!")
    assert {:error, "signature is not base64"} = SNS.verify(msg)
  end

  test "rejects unknown message types and signature versions", %{key: key, cert_url: url} do
    assert {:error, "unknown message type" <> _} =
             notification(url) |> Map.put("Type", "Other") |> sign(key) |> SNS.verify()

    assert {:error, "unknown signature version" <> _} =
             notification(url) |> Map.put("SignatureVersion", "3") |> sign(key) |> SNS.verify()
  end

  test "rejects a certificate that cannot be downloaded", %{key: key, cert_url: url} do
    Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 404, body: "not found"} end)

    assert {:error, "cannot fetch certificate" <> _} =
             notification(url) |> sign(key) |> SNS.verify()
  end

  test "downloads each certificate once", %{key: key, cert_url: url} do
    assert :ok = notification(url) |> sign(key) |> SNS.verify()

    Tesla.Mock.mock(fn _ -> %Tesla.Env{status: 500} end)
    assert :ok = notification(url) |> sign(key) |> SNS.verify()
  end
end
