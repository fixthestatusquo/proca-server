defmodule Proca.Service.SMTPTest do
  use Proca.DataCase
  alias Proca.Service

  @tls_service %Service{user: "joe", password: "qwerty", host: "tls://smtp.mail.op"}

  test "tls config" do
    c = Proca.Service.SMTP.config(@tls_service)

    assert c[:relay] == "smtp.mail.op"
    assert c[:port] == 25
    assert c[:tls] == :always
    assert c[:tls_options][:verify] == :verify_peer
    assert c[:tls_options][:server_name_indication] == 'smtp.mail.op'
    assert is_list(c[:tls_options][:cacerts])
    assert length(c[:tls_options][:cacerts]) > 0
    assert {vf, []} = c[:tls_options][:verify_fun]
    assert is_function(vf)

    c = Proca.Service.SMTP.config(%{@tls_service | host: @tls_service.host <> ":1234"})

    assert c[:port] == 1234

    c = Proca.Service.SMTP.config(%{@tls_service | host: "ssl://secure.org"})

    assert c[:relay] == "secure.org"
    assert c[:port] == 465
    assert c[:ssl] == true
    assert c[:sockopts][:verify] == :verify_peer
    assert c[:sockopts][:server_name_indication] == 'secure.org'
    assert is_list(c[:sockopts][:cacerts])
    assert length(c[:sockopts][:cacerts]) > 0
  end

  test "smtps config" do
    s = %Service{user: "joe", password: "qwerty", host: "smtps://smtp.mail.op"}
    c = Proca.Service.SMTP.config(s)

    assert c[:relay] == "smtp.mail.op"
    assert c[:port] == 465
    assert c[:ssl] == true
    assert c[:sockopts][:verify] == :verify_peer
    assert c[:sockopts][:server_name_indication] == 'smtp.mail.op'
    assert is_list(c[:sockopts][:cacerts])
    assert length(c[:sockopts][:cacerts]) > 0

    # explicit port overrides default
    c2 = Proca.Service.SMTP.config(%{s | host: "smtps://smtp.mail.op:246"})
    assert c2[:port] == 246

    # ssl:// and smtps:// both produce ssl: true with sockopts
    c3 = Proca.Service.SMTP.config(%{s | host: "smtps://secure.org:587"})
    assert c3[:ssl] == true
    assert c3[:port] == 587
    assert c3[:sockopts][:verify] == :verify_peer
    assert c3[:sockopts][:server_name_indication] == 'secure.org'
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
