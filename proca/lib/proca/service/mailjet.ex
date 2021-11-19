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
  alias Proca.Service.{EmailTemplate, EmailBackend}
  alias Swoosh.Adapters.Mailjet
  alias Swoosh.Email
  import Logger

  @api_url "https://api.mailjet.com/v3"
  @template_path "/REST/template"

  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def list_templates(%Org{template_backend: %Service{} = srv}) do
    case Service.json_request(srv, "#{@api_url}#{@template_path}", auth: :basic) do
      {:ok, 200, %{"Data" => templates}} -> {:ok, templates |> Enum.map(&template_from_json/1)}
      {:ok, 401} -> {:error, "not authenticated"}
      {:error, err} -> {:error, err}
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
  def put_recipient(email, recipient) do
    email
    |> Email.to({recipient.first_name, recipient.email})
    |> Email.put_provider_option(:variables, recipient.fields)
  end

  @impl true
  def put_template(email, %EmailTemplate{ref: ref}) when is_integer(ref) do
    email
    |> Email.put_provider_option(:template_id, ref)
  end

  def put_template(email, %EmailTemplate{subject: subject, html: html, text: text}) 
    when is_bitstring(subject) and (is_bitstring(html) or is_bitstring(text)) do 

    email
    |> Email.subject(subject)
    |> Email.html_body(html)
    |> Email.text_body(text)
  end

  @impl true
  def put_reply_to(email, reply_to_email) do
    email
    |> Email.header("Reply-To", reply_to_email)
  end

  @impl true
  def put_custom_id(email, custom_id) do
    email
    |> Email.put_provider_option(:custom_id, custom_id)
  end

  @impl true
  def deliver(emails, %Org{email_backend: srv}) do
    case Mailjet.deliver_many(emails, config(srv)) do
      {:ok, _} -> :ok
      {:error, {_code, %{"ErrorMessage" => msg}}} ->
        raise EmailBackend.NotDelivered.exception(msg)
      {:error, reason} ->
        raise EmailBackend.NotDelivered.exception("unknown error #{inspect(reason)})")
    end
  end

  @impl true
  def handle_bounce(params) do
    {type, id} = parse_type(String.split(Map.get(params, "CustomID"), ":", trim: true))
    bounce_params = %{
      id: id,
      email: Map.get(params, "email"),
      reason: String.to_atom(Map.get(params, "event"))
    }

    case type do
      :action -> Supporter.handle_bounce(bounce_params)
      :target -> Target.handle_bounce(bounce_params)
    end
  end

  defp parse_type(["action" | [tail | _]]), do: {:action, tail}
  defp parse_type(["target" | [tail | _]]), do: {:target, tail}
  defp parse_type(args), do: {:empty, nil}

  def config(%Service{name: :mailjet, user: u, password: p}) do
    %{
      api_key: u,
      secret: p
    }
  end
end
