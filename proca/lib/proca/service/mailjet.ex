defmodule Proca.Service.Mailjet do
  @moduledoc """
  Mailjet Email Backend

  Template ids (refs) are integers

  Templates:
  - Use transactional templates (not campaign)
  - Test thoroughly with their preview - MJ provides no debugging otherwise (just HTTP500 on send)
  - Fields can have underscores
  - Use {{var:foo_bar:"default"}} even with an empty default!
  - You cannot use default in some places: for example in attributes (href value).
  - You can conditionally show a block: use foo:"" in the field - but you need to use “greater then” + start of the string - no way to input “not empty” condition
  - The links prohibit use of default "" - so you must provide or hide it.
  - Use {% if var:givenname:"" %} and {% endif %} for conditional block

  The bounce endpoint is `/webhook/mailjet`.

  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.{Org, Service, Supporter, Target}
  alias Proca.Action.Message
  alias Proca.Service.EmailTemplate
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
  def list_templates(%Org{email_backend: %Service{} = srv} = org, lst \\ []) do
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

  def put_template(email, nil), do: email

  def put_template(email, %EmailTemplate{ref: ref}) when is_integer(ref) do
    email
    |> Email.put_provider_option(:template_id, ref)
  end

  def put_template(email, tmpl = %EmailTemplate{ref: ref}) when is_bitstring(ref) do
    put_template(email, %{tmpl | ref: String.to_integer(ref)})
  end

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

    Mailjet.deliver_many(emails, config(srv))
    |> handle_return(emails)
  end

  # Warning! Swoosh Mailjet adapter will return an inconsistent error data shape:
  #
  # Sending `[one_bad_email]`
  #
  # ```
  # EmailBackend.deliver([a], io)
  # {:error,
  #  {400,
  #   %{
  #     "Errors" => [
  #       %{
  #         "ErrorCode" => "mj-0013",
  #         "ErrorIdentifier" => "b3cd2840-18a3-44c3-97e3-45a19029902f",
  #         "ErrorMessage" => "\"marcin.@cahoots.pl\" is an invalid email address.",
  #         "ErrorRelatedTo" => ["To[0].Email"],
  #         "StatusCode" => 400
  #       }
  #     ],
  #     "Status" => "error"
  #   }}}
  # ```
  #
  # Sending `[one_bad_email, one_good_email]`
  #
  # ```
  # {:error,
  #  {400,
  #   [
  #     %{
  #       "Errors" => [
  #         %{
  #           "ErrorCode" => "mj-0013",
  #           "ErrorIdentifier" => "e37bcc6f-6821-414e-97df-528ec18e201e",
  #           "ErrorMessage" => "\"marcin.@cahoots.pl\" is an invalid email address.",
  #           "ErrorRelatedTo" => ["To[0].Email"],
  #           "StatusCode" => 400
  #         }
  #       ],
  #       "Status" => "error"
  #     },
  #     %{id: 1152921519812251571}
  #   ]}}
  # ```
  defp handle_return({:ok, _}, _) do
    :ok
  end

  # Re-wrap the errors in a list to fix inconsistent swoosh behavior
  # XXX fixed on 1.12.2022
  # defp handle_return({:error, {code, status}}, emails) when is_map(status) do
  #   handle_return({:error, {code, [status]}}, emails)
  # end

  defp handle_return({:error, {_code, statuses}}, _) when is_list(statuses) do
    {:error,
     Enum.map(
       statuses,
       fn
         %{id: _} ->
           :ok

         # drop fatal emails
         %{"Errors" => errors} ->
           if fatal_error?(errors) do
             Sentry.capture_message("Silently dropping email: #{error_message(errors)}",
               result: :none
             )

             :ok
           else
             {:error, error_message(errors)}
           end
       end
     )}
  end

  defp handle_return({:error, reason}, emails) do
    Sentry.capture_message("Mailjet: failed HTTP request to API #{inspect(reason)}")

    error("Mailjet cannot deliver email batch! #{inspect(reason)}")
    {:error, Enum.map(emails, fn _ -> {:error, reason} end)}
  end

  def fatal_error?(errors) when is_list(errors) do
    Enum.any?(errors, &Map.has_key?(&1, "ErrorRelatedTo"))
  end

  def error_message([%{"ErrorMessage" => error_msg} | _]) do
    error_msg
  end

  defp put_assigns(%Email{assigns: assigns} = email) do
    Email.put_provider_option(email, :variables, assigns)
  end

  defp put_custom(%Email{private: %{custom_id: custom_id}} = email) do
    Email.put_provider_option(email, :custom_id, custom_id)
  end

  defp put_custom(email), do: email

  @impl true
  def handle_bounce(%{"CustomID" => cid, "email" => email, "event" => reason} = event) do
    {type, id} = parse_custom_id(cid)

    error =
      ~w"error_related_to error comment"
      |> Enum.map(&event[&1])
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(": ")

    # IO.inspect(event, label: "BOUNCE EVENT")

    bounce_params = %{
      id: id,
      email: email,
      reason: String.to_existing_atom(reason),
      error: error
    }

    case type do
      :action -> Supporter.handle_bounce(bounce_params)
      :mtt -> Target.handle_bounce(bounce_params)
      _ -> {:error, :invalid_custom_id}
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
      _ -> {:error, :invalid_custom_id}
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
