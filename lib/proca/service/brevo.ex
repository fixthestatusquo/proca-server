defmodule Proca.Service.Brevo do
  @moduledoc """
  Brevo transactional email backend.

  Configure the Service record with:
  - `password` — Brevo API key

  Templates are managed in the Brevo dashboard; their integer IDs are stored as
  `EmailTemplate.ref` (string). The Brevo template engine uses `{{ params.firstName }}`
  syntax, and all merge tags from `EmailMerge` are passed as `params`.

  Bounce/event webhook endpoint: POST /webhook/brevo
  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.{Org, Service, Supporter, Target}
  alias Proca.Action.Message
  alias Proca.Service.EmailTemplate
  alias Swoosh.Email
  import Logger
  import Proca.Service.EmailBackend, only: [parse_custom_id: 1]

  @api_url "https://api.brevo.com/v3"
  @bounce_events ~w(bounced spam unsubscribed blocked)

  @impl true
  def supports_templates?(_org), do: true

  @impl true
  def batch_size(), do: 1

  @impl true
  def list_templates(%Org{email_backend: %Service{} = srv} = org) do
    fetch_templates(srv, org, [], 0)
  end

  defp fetch_templates(srv, org, acc, offset) do
    url = "#{@api_url}/smtp/templates?templateStatus=true&limit=50&offset=#{offset}"

    case Service.json_request(srv, url, auth: :api_key) do
      {:ok, 200, %{"templates" => templates}} ->
        mapped = Enum.map(templates, &template_from_json/1)

        if length(mapped) == 50 do
          fetch_templates(srv, org, acc ++ mapped, offset + 50)
        else
          {:ok, acc ++ mapped}
        end

      {:ok, 401} ->
        {:error, "not authenticated"}

      {:error, err} ->
        {:error, err}

      x ->
        error("Brevo list_templates unexpected result: #{inspect(x)}")
        {:error, "unexpected return from Brevo"}
    end
  end

  defp template_from_json(%{"id" => id, "name" => name}) do
    %EmailTemplate{ref: to_string(id), name: name}
  end

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
    body = build_payload(email)

    case Service.json_request(srv, "#{@api_url}/smtp/email", auth: :api_key, post: body) do
      {:ok, _, _} ->
        :ok

      {:ok, code} ->
        warn("Brevo deliver HTTP#{code}")
        {:error, "HTTP#{code}"}

      {:error, reason} ->
        error("Brevo deliver failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp build_payload(%Email{} = email) do
    %{}
    |> Map.put("to", Enum.map(email.to, fn {name, addr} -> %{"email" => addr, "name" => name} end))
    |> put_sender(email.from)
    |> put_content(Map.get(email.private, :template), email.subject, email.html_body, email.text_body)
    |> put_params(email.assigns)
    |> put_tags(Map.get(email.private, :custom_id))
  end

  defp put_sender(payload, {name, addr}),
    do: Map.put(payload, "sender", %{"email" => addr, "name" => name})

  defp put_sender(payload, nil), do: payload

  defp put_content(payload, %EmailTemplate{ref: ref}, _subj, _html, _text)
       when not is_nil(ref) do
    Map.put(payload, "templateId", String.to_integer(ref))
  end

  defp put_content(payload, _tmpl, subj, html, text) do
    payload
    |> maybe_put("subject", subj)
    |> maybe_put("htmlContent", html)
    |> maybe_put("textContent", text)
  end

  defp put_params(payload, assigns) when map_size(assigns) > 0,
    do: Map.put(payload, "params", assigns)

  defp put_params(payload, _), do: payload

  defp put_tags(payload, nil), do: payload
  defp put_tags(payload, cid), do: Map.put(payload, "tags", [cid])

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  @impl true
  def handle_bounce(%{"event" => event, "email" => email, "tags" => [cid | _]})
      when event in @bounce_events do
    :telemetry.execute([:proca, :brevo, :bounces], %{count: 1}, %{reason: event})

    {type, id} = parse_custom_id(cid)

    bounce_params = %{
      id: id,
      email: email,
      reason: brevo_event_to_status(event),
      error: event
    }

    case type do
      :action -> Supporter.handle_bounce(bounce_params)
      :mtt -> Target.handle_bounce(bounce_params)
      _ -> {:error, :invalid_custom_id}
    end
  end

  @impl true
  def handle_bounce(params) do
    warn("Malformed Brevo bounce: #{inspect(params)}")
  end

  @impl true
  def handle_event(%{"event" => event, "email" => email, "tags" => [cid | _]}) do
    :telemetry.execute([:proca, :brevo, :events], %{count: 1}, %{reason: event})

    {type, id} = parse_custom_id(cid)

    event_params = %{id: id, email: email, reason: String.to_existing_atom(event)}

    case type do
      :mtt -> Message.handle_event(event_params)
      _ -> :ok
    end
  end

  @impl true
  def handle_event(params) do
    warn("Malformed Brevo event: #{inspect(params)}")
  end

  defp brevo_event_to_status("bounced"), do: :bounce
  defp brevo_event_to_status("spam"), do: :spam
  defp brevo_event_to_status("unsubscribed"), do: :unsub
  defp brevo_event_to_status("blocked"), do: :blocked
end
