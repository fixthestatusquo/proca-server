defmodule Proca.Service.SMTPTest do
  use Proca.DataCase
  alias Proca.Service

  @tls_service %Service{user: "joe", password: "qwerty", host: "tls://smtp.mail.op"}

  test "tls config" do
    c = Proca.Service.SMTP.config(@tls_service)

    assert c[:relay] == "smtp.mail.op"
    assert c[:port] == 25

    c = Proca.Service.SMTP.config(%{@tls_service | host: @tls_service.host <> ":1234"})

    assert c[:port] == 1234

    c = Proca.Service.SMTP.config(%{@tls_service | host: "ssl://secure.org"})

    assert c[:relay] == "secure.org"
    assert c[:port] == 587
  end
end
