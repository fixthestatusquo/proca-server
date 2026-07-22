defmodule Proca.Service.Hubspot do
  @moduledoc """
  HubSpot transactional email backend (Single-Send API).

  Configure the Service record with `password` — `Bearer <private-app-access-token>`.

  `EmailTemplate.ref` holds the numeric HubSpot `emailId`. Contact merge data is sent
  as `customProperties` (not `contactProperties`, which is always sent empty so sending
  never mutates the recipient's CRM record).

  API reference: https://developers.hubspot.com/docs/api-reference/latest/marketing/transactional-emails/guide

  No bounce/event webhook is implemented. HubSpot's general webhooks/subscriptions API
  only covers CRM object and conversation events, not transactional single-send email
  events (https://developers.hubspot.com/docs/api-reference/latest/webhooks/guide); the
  transactional-email guide instead documents a polling Email Send Status API. The
  legacy Email Events API does expose BOUNCE/DROPPED/SPAMREPORT-style event types, but
  as a pull/query API, not a push webhook, and its payload has no `sendId`-shaped field
  to correlate back to a Proca message
  (https://developers.hubspot.com/docs/api-reference/legacy/reporting/email-analytics/guide).
  Revisit once real account access shows the actual mechanism (or confirms polling is
  the only option).
  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.{Org, Service}
  alias Swoosh.Email
  import Logger

  @api_url "https://api.hubapi.com/marketing/transactional/2026-03/single-email/send"

  @impl true
  def supports_templates?(_org), do: true

  @impl true
  def batch_size(), do: 1

  @impl true
  def list_templates(%Org{}), do: {:error, "not supported, enter the emailId manually"}

  @impl true
  def deliver(emails, org) when is_list(emails) do
    results = Enum.map(emails, &deliver(&1, org))

    if Enum.all?(results, &(&1 == :ok)) do
      :ok
    else
      {:error, results}
    end
  end

  @impl true
  def deliver(%Email{} = email, %Org{email_backend: %Service{} = srv}) do
    custom_id = Map.get(email.private, :custom_id)

    case build_payload(email) do
      {:ok, body} ->
        case Service.json_request(srv, @api_url, auth: :header, post: body) do
          {:ok, code, _} when code in [200, 201] ->
            :ok

          {:ok, code, response_body} ->
            error(
              "Hubspot deliver HTTP#{code} custom_id=#{log_custom_id(custom_id)} url=#{@api_url} request=#{inspect(request_summary(body))} response=#{inspect(response_body)}"
            )

            {:error, "HTTP#{code}"}

          {:error, reason} ->
            error(
              "Hubspot deliver failed custom_id=#{log_custom_id(custom_id)} url=#{@api_url} request=#{inspect(request_summary(body))} reason=#{inspect(reason)}"
            )

            {:error, reason}
        end

      {:error, reason} ->
        error("Hubspot deliver rejected custom_id=#{log_custom_id(custom_id)}: #{reason}")
        {:error, reason}
    end
  end

  defp log_custom_id("user:" <> _email), do: "user:[REDACTED]"
  defp log_custom_id(custom_id), do: custom_id

  defp request_summary(body) do
    %{
      email_id: body["emailId"],
      message_fields: body["message"] |> Map.keys() |> Enum.sort(),
      custom_properties: body["customProperties"] |> Map.keys() |> Enum.sort()
    }
  end

  @spec build_payload(Email.t()) :: {:ok, map()} | {:error, String.t()}
  def build_payload(%Email{} = email) do
    if length(email.to) > 1,
      do:
        error(
          "Hubspot build_payload: #{length(email.to)} recipients on a transactional email (custom_id=#{Map.get(email.private, :custom_id)}), expected 1"
        )

    with {:ok, to} <- recipient(email),
         {:ok, email_id} <- template_id(email) do
      payload = %{
        "emailId" => email_id,
        "message" => build_message(email, to),
        # always sent, always empty: sending must never mutate the recipient's CRM record
        "contactProperties" => %{},
        "customProperties" => email.assigns
      }

      {:ok, payload}
    end
  end

  defp recipient(%Email{to: [{_name, addr} | _]}), do: {:ok, addr}
  defp recipient(%Email{to: []}), do: {:error, "no recipient on email"}

  defp template_id(%Email{private: private}) do
    case Map.get(private, :template) do
      %{ref: ref} when not is_nil(ref) ->
        case Integer.parse(to_string(ref)) do
          {int, ""} -> {:ok, int}
          _ -> {:error, "invalid HubSpot emailId (external_id): #{inspect(ref)}"}
        end

      _ ->
        {:error, "no template configured (missing external_id on EmailTemplate)"}
    end
  end

  defp build_message(
         %Email{from: from, reply_to: reply_to, cc: cc, bcc: bcc, private: private},
         to
       ) do
    %{"to" => to}
    |> put_from(from)
    |> put_send_id(Map.get(private, :custom_id))
    |> put_reply_to(reply_to)
    |> put_addr_list("cc", cc)
    |> put_addr_list("bcc", bcc)
  end

  defp put_from(message, {"", addr}), do: Map.put(message, "from", addr)
  defp put_from(message, {name, addr}), do: Map.put(message, "from", "#{name} <#{addr}>")
  defp put_from(message, nil), do: message

  defp put_send_id(message, nil), do: message
  defp put_send_id(message, cid), do: Map.put(message, "sendId", cid)

  defp put_reply_to(message, nil), do: message
  defp put_reply_to(message, {"", addr}), do: Map.put(message, "replyTo", [addr])

  defp put_reply_to(message, {name, addr}),
    do: Map.put(message, "replyTo", ["#{name} <#{addr}>"])

  defp put_addr_list(message, _key, []), do: message

  defp put_addr_list(message, key, addrs),
    do: Map.put(message, key, Enum.map(addrs, fn {_name, addr} -> addr end))

  @impl true
  def handle_bounce(_), do: :ok

  @impl true
  def handle_event(_), do: :ok
end
