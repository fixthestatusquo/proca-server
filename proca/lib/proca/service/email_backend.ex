defmodule Proca.Service.EmailBackend do
  @moduledoc """
  EmailBackend behaviour specifies what we want to expect from an email backend.
  We are using Bamboo for sending emails - it is very convenient because it has lots of adapters.
  However, we also need to be able to work with templates and Bamboo does not have this.

  ## Recipients
  Recipients of transaction emails are Supporters. 


  1. We prefer to use a template system, for sending emails in batch.
  2. If this is not available, send them one by one

  ## Templates

  We want to avoid having an email template editor in Proca.

  1. We prefer using template if there is web editor for templates
  2. We can also pull the content from a CMS, push as template
  3. We can use email template from `ActionPage.config`
  """

  alias Proca.{Org, Service}
  alias Proca.Service.{EmailTemplate, EmailRecipient}
  alias Bamboo.Email

  # Template management
  @callback supports_templates?(org :: %Org{}) :: true | false
  @callback list_templates(org :: %Org{}) :: [%EmailTemplate{}]
  @callback upsert_template(org :: %Org{}, template :: %EmailTemplate{}) ::
              :ok | {:error, reason :: String.t()}
  @callback get_template(org :: %Org{}, ref :: String.t()) ::
              {:ok, %EmailTemplate{}} | {:error, reason :: String.t()}

  @type recipient :: %EmailRecipient{}

  @callback put_recipients(email :: %Email{}, recipients :: [recipient]) :: %Email{}
  @callback put_template(email :: %Email{}, template :: %EmailTemplate{}) :: %Email{}
  @callback put_reply_to(email :: %Email{}, reply_to_email :: String.t) :: %Email{}
  @callback deliver(%Email{}, %Org{}) :: any()

  def service_module(:mailjet) do
    Proca.Service.Mailjet
  end

  def supports_templates?(org = %Org{template_backend: %Service{name: name}}) do
    service_module(name)
    |> apply(:supports_templates?, [org])
  end

  @spec deliver([%EmailRecipient{}], %Org{}, %EmailTemplate{}) :: :ok
  def deliver(recipients, org = %Org{email_backend: %Service{name: name}}, email_template) do
    backend = service_module(name)

    e = Email.from(%Email{}, from(org))

    e = if elem(e.from, 1) != org.email_from do
      apply(backend, :put_reply_to, [e, org.email_from])
    else
      e
    end

    e = apply(backend, :put_recipients, [e, recipients])
    e = apply(backend, :put_template, [e, email_template])
    apply(backend, :deliver, [e, org])
  end

  defp from(org = %Org{id: org_id, email_backend: %Service{org_id: org_id}}) do
    {org.title, org.email_from}
  end

  defp from(org = %Org{email_backend: %Service{org: via_org}}) do
    via_from(org, via_org)
  end

  defp via_from(%{title: org_title, email_from: email_from}, %{email_from: via_email_from})
  when not is_nil(email_from) and not is_nil(via_email_from) do
    [user, _domain] = Regex.split(~r/@/, email_from)
    [via_user, via_domain] = Regex.split(~r/@/, via_email_from)

    {org_title, "#{via_user}+#{user}@#{via_domain}"}
  end

  defp via_from(_o1, _o2) do
    nil
  end

  defmodule NotDelivered do
    defexception [:message]

    def exception(msg) when is_bitstring(msg) do
      %NotDelivered{message: msg}
    end

    def exception(original_exception) do
      %NotDelivered{message: original_exception.message}
    end
  end
end
