defmodule Proca.Service.EmailBackend do
  @moduledoc """
  EmailBackend behaviour specifies what we want to expect from an email backend.
  We are using Swoosh for sending emails - it is very convenient because it has lots of adapters.
  However, we also need to be able to work with templates and Swoosh does not have this.

  ## Recipients
  Recipients of transaction emails are Supporters or Targets

  Previoudly we used EmailRecipient to carry envelope data, but now we want to
  just use Swoosh.Email because it is one abstraction layer less and it can hold
  all the information we need.

  We make use of Email fields:
  - assigns - to hold EmailRecipient.fields
  - private[:template] - template
  - private[:custom_id] - custom_id

  1. We prefer to use a template system, for sending emails in batch.
  2. If this is not available, send them one by one

  ## Templates

  We want to avoid having an email template editor in Proca.

  1. We prefer using template if there is web editor for templates
  2. We can also pull the content from a CMS, push as template
  3. We can use email template from `ActionPage.config`

  ## Sender Domain/Adddress

  1. We assume a sender has email backend with full domain support of their
  org.from_email address

  2. We can check this on time of setting the backend - querying the domains via
  API (when available - similar to how we check the template)

  3. We can do from email "spoofing" to use mixed FROM and Reply-To. Eg. A sends
  via B backend, their from is hello@a.org, the from will be hello+a.org@b.org,
  with Reply-To hello@a.org.

  4. We can use this also for MTT, but this creates a security risk of spoofing
  the real users' emails if we don't put username after + (member+marcin@a.org)
  but just in fromt of the @ (marcin@a.org). This could result into some serious
  problems, if someone abuses this to impersonate root@a.org, postmaster@a.org,
  or a legitimate user. Those who will have a dedicated campaign domain might
  feel in the safe, but imagine someone using this to access DNS provider for
  the domain... Another solution - if member+marcin@ is not good enought, to use
  a fixed prefix/postfix like member_marcin@.
  """

  alias Proca.{Org, Service}
  alias Proca.Service.{EmailTemplate, EmailRecipient}
  alias Swoosh.Email
  import Proca.Stage.Support, only: [flatten_keys: 2]

  # Template management
  @callback supports_templates?(org :: %Org{}) :: true | false
  @callback list_templates(org :: %Org{}) ::
              {:ok, [%EmailTemplate{}]} | {:error, reason :: String.t()}
  @callback upsert_template(org :: %Org{}, template :: %EmailTemplate{}) ::
              :ok | {:error, reason :: String.t()}
  @callback get_template(org :: %Org{}, ref :: String.t()) ::
              {:ok, %EmailTemplate{}} | {:error, reason :: String.t()}

  @callback put_template(email :: %Email{}, template :: %EmailTemplate{}) :: %Email{}

  @callback deliver([%Email{}], %Org{}) :: any()

  @callback handle_bounce(params :: any()) :: any()

  @callback batch_size() :: number

  def service_module(:mailjet), do: Proca.Service.Mailjet

  def service_module(:testmail), do: Proca.TestEmailBackend

  def batch_size(org = %Org{email_backend: %Service{name: name}}) do
    service_module(name).batch_size()
  end

  def supports_templates?(org = %Org{template_backend: %Service{name: name}}) do
    service_module(name)
    |> apply(:supports_templates?, [org])
  end

  def list_templates(org = %Org{template_backend: %Service{name: name}}) do
    service_module(name)
    |> apply(:list_templates, [org])
  end

  @doc """
  Delivers an email using EmailTemplate to a list of EmailRecipients. Uses Org's email service.
  Can throw EmailBackend.NotDelivered which wraps service error.
  """
  @spec deliver([%Email{}] | [%EmailRecipient{}], %Org{}, %EmailTemplate{} | nil) :: :ok
  def deliver(recipients, org = %Org{email_backend: %Service{name: name}}, email_template \\ nil) do
    backend = service_module(name)

    emails =
      recipients
      |> Enum.map(fn e ->
        e
        |> from_recipient()
        |> prepare_fields()
        |> determine_sender(org)
        |> prepare_template(email_template)
      end)

    apply(backend, :deliver, [emails, org])
  end

  def from_recipient(%EmailRecipient{
        email: to,
        first_name: fname,
        ref: ref,
        fields: fld,
        custom_id: cid
      }) do
    Email.new(to: to, assigns: %{first_name: fname, ref: ref} |> Map.merge(fld))
    |> from_recipient_custom_id(cid)
  end

  def from_recipient(email = %Email{}), do: email

  defp from_recipient_custom_id(email, nil), do: email
  defp from_recipient_custom_id(email, cid), do: Email.put_private(email, :custom_id, cid)

  defp prepare_template(email, nil), do: email

  defp prepare_template(email, tmpl = %EmailTemplate{}),
    do: Email.put_private(email, :template, tmpl)

  @deprecated "Use Email.header(\"Reply-To\", addr)directly"
  def put_reply_to(email, reply_to_email) do
    email
    |> Email.header("Reply-To", reply_to_email)
  end

  @deprecated "Use Email.to directly"
  def put_recipient(email, %EmailRecipient{} = recipient) do
    email
    |> Email.to({recipient.first_name, recipient.email})
  end

  @doc """
  Determine the From + Reply to of the email.

  Support these cases:
  1. No from set, and current org sends - use the org.email_from
  2. No from set, and org sends via other org - set the orgs FROM, then pass to other clause to get a mixed format
  3. FROM set, we need to check the address - if email is different then sending one, replace FROM email with a mix.

  """
  def determine_sender(
        email = %Email{from: nil},
        org = %Org{id: id, email_backend: %Service{org_id: id}}
      ) do
    Email.from(email, {org.title, org.email_from})
  end

  def determine_sender(email = %Email{from: nil}, org = %Org{email_backend: %Service{}}) do
    email
    |> Email.from({org.title, org.email_from})
    |> determine_sender(org)
  end

  def determine_sender(
        email = %Email{from: {from_name, from_email}},
        org = %Org{email_backend: srv}
      ) do
    %{org: via_org} = Proca.Repo.preload(srv, [:org])

    [username, domain] = Regex.split(~r/@/, from_email)
    [via_username, via_domain] = Regex.split(~r/@/, via_org.email_from)

    cond do
      # FROM set, but matching the sending backend
      from_email == via_org.email_from ->
        email

      # One org borrows the others backend
      from_email == org.email_from ->
        email
        |> Email.from({from_name, "#{via_username}+#{domain}@#{via_domain}"})
        |> Email.header("Reply-To", from_email)

      # Any from email - we will use the username here
      true ->
        email
        |> Email.from({from_name, "#{via_username}+#{username}@#{via_domain}"})
        |> Email.header("Reply-To", from_email)
    end
  end

  # template renderers of Mailjet and friends are happier with a flat list of vars
  defp prepare_fields(%Email{assigns: fields} = email) do
    %{email | assigns: flatten_keys(fields, "")}
  end

  defmodule NotDelivered do
    defexception [:message, :reason]

    def exception(msg) when is_bitstring(msg) do
      %NotDelivered{message: msg}
    end

    def exception(original_exception) do
      %NotDelivered{message: original_exception.message}
    end
  end
end
