defmodule Proca.Stage.WebhookTest do
  use Proca.DataCase

  alias Proca.Repo
  alias Proca.Factory
  alias Proca.Stage.Webhook

  defp with_backend(org, field) do
    service =
      Factory.insert(:email_backend, name: :webhook, host: "https://example.org/push", org: org)

    org
    |> Repo.preload([:push_backend, :event_backend])
    |> Ecto.Changeset.change([{field, service}])
    |> Repo.update!()
  end

  defp handle(org, schema) do
    msg = %Broadway.Message{
      data: %{"schema" => schema, "eventType" => "new_org"},
      acknowledger: {Broadway.CallerAcknowledger, {self(), make_ref()}, :ok}
    }

    batch_info = %Broadway.BatchInfo{batcher: :default, batch_key: :any}

    [result] = Webhook.handle_batch(:default, [msg], batch_info, %{org: org})
    result
  end

  describe "handle_batch(:default, ...)" do
    test "discards (does not crash) when push_backend is set but the message needs event_backend" do
      # push_backend set, event_backend intentionally left nil - start_for?/1
      # would start this consumer (push_backend is :webhook), but a system
      # event needs event_backend specifically.
      org = Factory.insert(:org) |> with_backend(:push_backend)

      result = handle(org, "proca:event:2")

      assert {:failed, _reason} = result.status
    end

    test "discards (does not crash) when event_backend is set but the message needs push_backend" do
      # mirror case: event_backend set, push_backend intentionally left nil -
      # start_for?/1 would start this consumer (event_backend is :webhook),
      # but an action message needs push_backend specifically.
      org = Factory.insert(:org) |> with_backend(:event_backend)

      result = handle(org, "proca:action:2")

      assert {:failed, _reason} = result.status
    end
  end
end
