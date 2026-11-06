defmodule Proca.Service.HubspotTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  alias Proca.{Org, Service}
  alias Proca.Service.Hubspot
  alias Proca.Service.EmailTemplate
  alias Swoosh.Email

  setup do
    adapter = Application.get_env(:tesla, :adapter)
    Application.put_env(:tesla, :adapter, Tesla.Mock)

    on_exit(fn -> Application.put_env(:tesla, :adapter, adapter) end)

    :ok
  end

  defp email_with_template(ref) do
    Email.new()
    |> Email.to({"Jo", "jo@example.com"})
    |> Email.from({"Org", "org@example.com"})
    |> Email.assign(:firstName, "Jo")
    |> Swoosh.Email.put_private(:template, %EmailTemplate{ref: ref})
    |> Swoosh.Email.put_private(:custom_id, "action:1")
  end

  defp hubspot_org do
    %Org{email_backend: %Service{password: "Bearer private-token"}}
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

  describe "fullConfirmLink" do
    defp custom_properties(assigns) do
      email =
        Enum.reduce(assigns, email_with_template("123"), fn {k, v}, e ->
          %{e | assigns: Map.put(e.assigns, k, v)}
        end)

      {:ok, payload} = Hubspot.build_payload(email)
      payload["customProperties"]
    end

    test "is composed from the confirm link, location and content" do
      props =
        custom_properties(%{
          "confirmLink" => "https://api.test/link/s/1/accept/REF",
          "trackingLocation" => "https://site.test/sign",
          "trackingContent" => "abc"
        })

      assert props["fullConfirmLink"] ==
               "https://api.test/link/s/1/accept/REF?redir=https%3A%2F%2Fsite.test%2Fsign%3Fproca_go%3Ddonate_Redirect%26utm_content%3Dabc"
    end

    test "joins with & when the confirm link already has a query (reminder)" do
      props =
        custom_properties(%{
          "confirmLink" => "https://api.test/link/s/1/accept/REF?reminder=1",
          "trackingLocation" => "https://site.test/sign",
          "trackingContent" => "abc"
        })

      assert String.starts_with?(
               props["fullConfirmLink"],
               "https://api.test/link/s/1/accept/REF?reminder=1&redir=https%3A%2F%2F"
             )
    end

    test "redir decodes to a valid url when location has a query and content special chars" do
      props =
        custom_properties(%{
          "confirmLink" => "https://api.test/link/s/1/accept/REF",
          "trackingLocation" => "https://site.test/sign?a=1",
          "trackingContent" => "x&y z"
        })

      redir =
        URI.parse(props["fullConfirmLink"]).query |> URI.decode_query() |> Map.fetch!("redir")

      assert URI.parse(redir).query |> URI.query_decoder(:rfc3986) |> Enum.to_list() == [
               {"a", "1"},
               {"proca_go", "donate_Redirect"},
               {"utm_content", "x&y z"}
             ]
    end

    test "has an empty utm_content when the action has no content" do
      props =
        custom_properties(%{
          "confirmLink" => "https://api.test/link/s/1/accept/REF",
          "trackingLocation" => "https://site.test/sign",
          "trackingContent" => ""
        })

      assert String.ends_with?(props["fullConfirmLink"], "utm_content%3D")
    end

    test "is the plain confirm link when location is unknown" do
      link = "https://api.test/link/s/1/accept/REF"

      assert custom_properties(%{"confirmLink" => link})["fullConfirmLink"] == link

      assert custom_properties(%{"confirmLink" => link, "trackingLocation" => ""})[
               "fullConfirmLink"
             ] == link
    end

    test "is not added when the email has no confirm link" do
      refute Map.has_key?(custom_properties(%{}), "fullConfirmLink")
    end
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

  test "delivery client error logs sanitized request and response diagnostics" do
    Tesla.Mock.mock(fn _env ->
      Tesla.Mock.json(%{"message" => "invalid payload"},
        status: 400,
        headers: [{"content-type", "application/json"}]
      )
    end)

    email =
      email_with_template("123")
      |> Email.assign(:firstName, "Robert'; touch /tmp/exploited; #")
      |> Email.put_private(:custom_id, "user:private@example.com")

    log =
      capture_log(fn ->
        assert {:error, "HTTP400"} = Hubspot.deliver(email, hubspot_org())
      end)

    assert log =~ "email_id: 123"
    assert log =~ "custom_id=user:[REDACTED]"
    assert log =~ "custom_properties: [:firstName]"
    assert log =~ "response=%{\"message\" => \"invalid payload\"}"
    refute log =~ "jo@example.com"
    refute log =~ "Robert"
    refute log =~ "private-token"
    refute log =~ "private@example.com"
    refute log =~ "curl"
  end
end
