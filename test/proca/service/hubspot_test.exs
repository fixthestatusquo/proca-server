defmodule Proca.Service.HubspotTest do
  use ExUnit.Case, async: true

  alias Proca.Service.Hubspot
  alias Proca.Service.EmailTemplate
  alias Swoosh.Email

  defp email_with_template(ref) do
    Email.new()
    |> Email.to({"Jo", "jo@example.com"})
    |> Email.from({"Org", "org@example.com"})
    |> Email.assign(:firstName, "Jo")
    |> Swoosh.Email.put_private(:template, %EmailTemplate{ref: ref})
    |> Swoosh.Email.put_private(:custom_id, "action:1")
  end

  test "build_payload sends emailId, recipient, sendId, and contact data as customProperties" do
    {:ok, payload} = Hubspot.build_payload(email_with_template("123"))

    assert payload["emailId"] == 123
    assert payload["message"]["to"] == "jo@example.com"
    assert payload["message"]["from"] == "Org <org@example.com>"
    assert payload["message"]["sendId"] == "action:1"
    assert payload["customProperties"] == %{firstName: "Jo"}
  end

  test "build_payload always sends contactProperties empty, never mutating the CRM record" do
    {:ok, payload} = Hubspot.build_payload(email_with_template("123"))

    assert payload["contactProperties"] == %{}
  end

  test "build_payload sends customProperties even when there are no assigns" do
    email =
      Email.new()
      |> Email.to({"Jo", "jo@example.com"})
      |> Swoosh.Email.put_private(:template, %EmailTemplate{ref: "123"})

    {:ok, payload} = Hubspot.build_payload(email)

    assert payload["customProperties"] == %{}
  end

  test "build_payload rejects a malformed template ref instead of crashing" do
    assert {:error, _} = Hubspot.build_payload(email_with_template("not-a-number"))
  end

  test "build_payload rejects a missing template instead of sending emailId: nil" do
    email = Email.new() |> Email.to({"Jo", "jo@example.com"})

    assert {:error, _} = Hubspot.build_payload(email)
  end

  test "build_payload rejects an email with no recipient instead of crashing" do
    email =
      Email.new()
      |> Swoosh.Email.put_private(:template, %EmailTemplate{ref: "123"})

    assert {:error, _} = Hubspot.build_payload(email)
  end

  test "build_payload forwards from without a name as a bare address" do
    email =
      Email.new()
      |> Email.to({"Jo", "jo@example.com"})
      |> Email.from("org@example.com")
      |> Swoosh.Email.put_private(:template, %EmailTemplate{ref: "123"})

    {:ok, payload} = Hubspot.build_payload(email)

    assert payload["message"]["from"] == "org@example.com"
  end

  test "build_payload forwards reply_to, cc, and bcc" do
    email =
      Email.new()
      |> Email.to({"Jo", "jo@example.com"})
      |> Email.reply_to({"Support", "support@example.com"})
      |> Email.cc([{"", "cc1@example.com"}, {"CC Two", "cc2@example.com"}])
      |> Email.bcc({"", "bcc1@example.com"})
      |> Swoosh.Email.put_private(:template, %EmailTemplate{ref: "123"})

    {:ok, payload} = Hubspot.build_payload(email)

    assert payload["message"]["replyTo"] == ["Support <support@example.com>"]
    assert payload["message"]["cc"] == ["cc1@example.com", "cc2@example.com"]
    assert payload["message"]["bcc"] == ["bcc1@example.com"]
  end

  test "handle_bounce and handle_event are no-ops (no webhook mechanism implemented)" do
    assert Hubspot.handle_bounce(%{"anything" => "goes"}) == :ok
    assert Hubspot.handle_event(%{"anything" => "goes"}) == :ok
  end
end
