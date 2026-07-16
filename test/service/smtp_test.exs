defmodule Proca.Service.SMTPTest do
  use Proca.DataCase
  alias Proca.Service

  @tls_service %Service{user: "joe", password: "qwerty", host: "tls://smtp.mail.op"}

  test "tls config" do
    c = Proca.Service.SMTP.config(@tls_service)

    assert c[:relay] == "smtp.mail.op"
    assert c[:port] == 25
    assert c[:tls] == :always
    assert [verify: :verify_peer, cacerts: cacerts] = c[:tls_options]
    assert is_list(cacerts)
    assert length(cacerts) > 0

    c = Proca.Service.SMTP.config(%{@tls_service | host: @tls_service.host <> ":1234"})

    assert c[:port] == 1234

    c = Proca.Service.SMTP.config(%{@tls_service | host: "ssl://secure.org"})

    assert c[:relay] == "secure.org"
    assert c[:port] == 465
    assert c[:ssl] == true
    assert [verify: :verify_peer, cacerts: cacerts2] = c[:sockopts]
    assert is_list(cacerts2)
    assert length(cacerts2) > 0
  end

  test "smtps config" do
    s = %Service{user: "joe", password: "qwerty", host: "smtps://smtp.mail.op"}
    c = Proca.Service.SMTP.config(s)

    assert c[:relay] == "smtp.mail.op"
    assert c[:port] == 465
    assert c[:ssl] == true
    assert [verify: :verify_peer, cacerts: cacerts] = c[:sockopts]
    assert is_list(cacerts)
    assert length(cacerts) > 0

    # explicit port overrides default
    c2 = Proca.Service.SMTP.config(%{s | host: "smtps://smtp.mail.op:246"})
    assert c2[:port] == 246

    # ssl:// and smtps:// both produce ssl: true with sockopts
    c3 = Proca.Service.SMTP.config(%{s | host: "smtps://secure.org:587"})
    assert c3[:ssl] == true
    assert c3[:port] == 587
    assert [verify: :verify_peer, cacerts: _] = c3[:sockopts]
  end

  describe "deliver/2" do
    test "empty list returns :ok" do
      org = %Proca.Org{
        name: "test-org",
        email_backend: %Service{
          user: "u",
          password: "p",
          host: "tls://smtp.example.com"
        }
      }

      assert Proca.Service.SMTP.deliver([], org) == :ok
    end

    test "put_message_id sets Message-Id header" do
      email =
        Swoosh.Email.new(to: {"Test", "test@example.com"})
        |> Swoosh.Email.put_private(:custom_id, "action:42")

      result = Proca.Service.SMTP.put_message_id(email)
      assert result.headers["Message-Id"] == "action:42"
    end
  end
end
