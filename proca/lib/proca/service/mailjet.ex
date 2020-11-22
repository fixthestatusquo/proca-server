defmodule Proca.Service.Mailjet do
  @moduledoc """
  Mailjet Email Backend
  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.{Org, Service}
  alias Proca.Service.{EmailTemplate, EmailBackend}
  alias Bamboo.{MailjetAdapter, MailjetHelper, Email}

  @api_url "https://api.mailjet.com/v3"
  @template_path "/REST/template"

  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def list_templates(%Org{template_backend: %Service{} = srv}) do
    case Service.json_request(srv, "#{@api_url}#{@template_path}", auth: :basic) do
      {:ok, 200, %{"Data" => templates}} -> templates |> Enum.map(&template_from_json/1)
      {:error, err} -> {:error, err}
      _x -> {:error, "unexpected return from mailjet list templates"}
    end
  end

  defp template_from_json(data) do
    %EmailTemplate{
      ref: Integer.to_string(data["ID"]),
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
  def put_recipients(email, recipients) do
    email
    |> Email.to([])
    |> Email.cc([])
    |> Email.bcc(
      Enum.map(
        recipients,
        fn %{first_name: name, email: eml} -> {name, eml} end
      )
    )
    |> MailjetHelper.put_recipient_vars(Enum.map(recipients, & &1.fields))
  end

  @impl true
  def put_template(email, %EmailTemplate{ref: ref}) do
    email
    |> MailjetHelper.template(ref)
    |> MailjetHelper.template_language(true)
  end

  @impl true
  def put_reply_to(email, reply_to_email) do
    email
    |> Email.put_header("Reply-To", reply_to_email)
  end

  @impl true
  def deliver(email, %Org{email_backend: srv}) do
    try do
      MailjetAdapter.deliver(email, config(srv))
    rescue
      e in MailjetAdapter.ApiError ->
        reraise EmailBackend.NotDelivered.exception(e), __STACKTRACE__
    end
  end

  def config(%Service{name: :mailjet, user: u, password: p}) do
    %{
      api_key: u,
      api_private_key: p
    }
  end
end
