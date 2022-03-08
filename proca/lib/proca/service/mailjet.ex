defmodule Proca.Service.Mailjet do
  @moduledoc """
  Mailjet Email Backend

  Templates:
  - Use transactional templates (not campaign)
  - Test thoroughly with their preview - MJ provides no debugging otherwise (just HTTP500 on send)
  - Fields can have underscores
  - Use {{var:foo_bar:"default"}} even with an empty default!
  - You cannot use default in some places: for example in attributes (href value).
  - You can conditionally show a block: use foo:"" in the field - but you need to use “greater then” + start of the string - no way to input “not empty” condition
  - The links prohibit use of default "" - so you must provide or hide it.
  - Use {% if var:givenname:"" %} and {% endif %} for conditional block

  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.{Org, Service, Supporter, Target}
  alias Proca.Action.Message
  alias Proca.Service.{EmailTemplate, EmailBackend, EmailRecipient}
  alias Swoosh.Adapters.Mailjet
  alias Swoosh.Email
  import Logger
  import Proca.Service.EmailBackend, only: [parse_custom_id: 1]

  @api_url "https://api.mailjet.com/v3"
  @template_path "/REST/template"

  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def batch_size(), do: 25

  @impl true
  def list_templates(%Org{template_backend: %Service{} = srv} = org, lst \\ []) do
    case Service.json_request(srv, "#{@api_url}#{@template_path}?limit=50&offset=#{length(lst)}",
           auth: :basic
         ) do
      {:ok, 200, %{"Data" => templates}} ->
        case Enum.map(templates, &template_from_json/1) do
          [] -> {:ok, lst}
          templates -> list_templates(org, lst ++ templates)
        end

      {:ok, 401} ->
        {:error, "not authenticated"}

      {:error, err} ->
        {:error, err}

      x ->
        error("Mailjet List Template API unexpected result: #{inspect(x)}")
        {:error, "unexpected return from mailjet list templates"}
    end
  end

  defp template_from_json(data) do
    %EmailTemplate{
      ref: data["ID"],
      name: data["Name"]
    }
  end

  @impl true
  def upsert_template(_org, _template) do
    {:error, "not implemneted"}
  end

  @impl true
  def get_template(_org, _template) do
    {:error, "not implemented"}
  end

  @impl true
  def put_template(email, nil), do: email

  def put_template(email, %EmailTemplate{ref: ref}) when is_integer(ref) do
    email
    |> Email.put_provider_option(:template_id, ref)
  end

  @impl true
  def put_template(email, tmpl = %EmailTemplate{ref: ref}) when is_bitstring(ref) do
    put_template(email, %{tmpl | ref: String.to_integer(ref)})
  end

  @impl true
  def put_template(email, %EmailTemplate{subject: subject, html: html, text: text})
      when is_bitstring(subject) and (is_bitstring(html) or is_bitstring(text)) do
    email
    |> Email.subject(subject)
    |> Email.html_body(html)
    |> Email.text_body(text)
  end

  @impl true
  def deliver(emails, %Org{email_backend: srv}) when is_list(emails) do
    emails =
      Enum.map(emails, fn e ->
        e
        |> put_assigns()
        |> put_template(Map.get(e.private, :template, nil))
        |> put_custom()
      end)

    case Mailjet.deliver_many(emails, config(srv)) do
      {:ok, _} ->
        :ok

      {:error, {_code, error_list}} when is_list(error_list) ->
        {:error,
         Enum.map(error_list, fn
           %{id: _} -> :ok
           %{"Errors" => [%{"ErrorMessage" => msg} | _]} -> {:error, msg}
           err -> {:error, inspect(err)}
         end)}

      {:error, reason} ->
        error("Dropping email batch! #{inspect(reason)} - ignoring this batch!")
        :ok
    end
  end

  defp put_assigns(%Email{assigns: assigns} = email) do
    Email.put_provider_option(email, :variables, assigns)
  end

  defp put_custom(%Email{private: %{custom_id: custom_id}} = email) do
    Email.put_provider_option(email, :custom_id, custom_id)
  end

  defp put_custom(email), do: email

  @impl true
  def handle_bounce(%{"CustomID" => cid, "email" => email, "event" => reason}) do
    {type, id} = parse_custom_id(cid)

    bounce_params = %{
      id: id,
      email: email,
      reason: String.to_existing_atom(reason)
    }

    case type do
      :action -> Supporter.handle_bounce(bounce_params)
      :mtt -> Target.handle_bounce(bounce_params)
    end
  end

  @impl true
  def handle_bounce(params) do
    warn("Malformed Mailjet bounce event: #{inspect(params)}")
  end

  @impl true
  def handle_event(%{"CustomID" => cid, "email" => email, "event" => reason}) do
    {type, id} = parse_custom_id(cid)

    event_params = %{
      id: id,
      email: email,
      reason: String.to_existing_atom(reason)
    }

    case type do
      :mtt -> Message.handle_event(event_params)
    end
  end

  @impl true
  def handle_event(params) do
    warn("Malformed Mailjet event: #{inspect(params)}")
  end

  def config(%Service{name: :mailjet, user: u, password: p}) do
    %{
      api_key: u,
      secret: p
    }
  end
end
