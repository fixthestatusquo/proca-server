defmodule Proca.Service.SESTest do
  use ExUnit.Case, async: true

  alias Proca.Service.SES
  alias Swoosh.Email

  describe "custom id on outgoing email" do
    test "is sent as header and as SES tags" do
      email =
        Email.new()
        |> Email.put_private(:custom_id, "mtt:42")
        |> SES.put_custom_id()

      assert email.headers["X-Proca-Id"] == "mtt:42"

      assert email.provider_options.tags == [
               %{name: "proca_type", value: "mtt"},
               %{name: "proca_id", value: "42"}
             ]
    end

    test "matches what SES sends back in a real bounce report" do
      # recorded from SES (simulator bounce), account id and ips replaced
      %{"mail" => %{"tags" => reported_tags, "headers" => reported_headers}} =
        "test/fixtures/ses/bounce_event.json" |> File.read!() |> Jason.decode!()

      email =
        Email.new()
        |> Email.put_private(:custom_id, "action:123")
        |> SES.put_custom_id()

      for %{name: name, value: value} <- email.provider_options.tags do
        assert reported_tags[name] == [value]
      end

      for {name, value} <- email.headers do
        assert %{"name" => name, "value" => value} in reported_headers
      end
    end

    test "is not added for user emails (tag values cannot hold an address)" do
      email =
        Email.new()
        |> Email.put_private(:custom_id, "user:jo@example.org")
        |> SES.put_custom_id()

      assert email.headers == %{}
      assert email.provider_options == %{}
    end
  end
end
