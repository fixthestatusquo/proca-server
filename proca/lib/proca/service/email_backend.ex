defmodule Proca.Service.EmailBackend do
  @moduledoc """
  EmailBackend behaviour specifies what we want to expect from an email backend.
  We are using Swoosh for sending emails - it is very convenient because it has lots of adapters.
  However, we also need to be able to work with templates and Swoosh does not have this.

  ## Recipients
  Recipients of transaction emails are Supporters, Targets, Users (in case of notifications)

  We use Swoosh.Email for passing email data.

  We make use of Email fields:
  - assigns - to hold merge tag values
  - private[:template] - template
  - private[:custom_id] - custom_id

  1. We use local email templates with single-sending
  2. We support batch sending for Mailjet, SES bulk api is not good.

  ## Templates

  1. We use a mustache templates stored in proca (email_templates table)
  2. Or a service-provider template system (for Mailjet)

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
  alias Proca.Service.{EmailTemplate, EmailMerge}
  alias Swoosh.Email
  import Proca.Stage.Support, only: [flatten_keys: 2]

  # Template management
  @callback supports_templates?(org :: %Org{}) :: true | false
  @callback list_templates(org :: %Org{}) ::
              {:ok, [%EmailTemplate{}]} | {:error, reason :: String.t()}

  @callback deliver([%Email{}], %Org{}) :: any()

  @callback handle_bounce(params :: any()) :: any()

  @callback handle_event(params :: any()) :: any()

  # XXX is this even used anywhere?
  @callback batch_size() :: number

  def service_module(:mailjet), do: Proca.Service.Mailjet

  def service_module(:ses), do: Proca.Service.SES

  def service_module(:testmail), do: Proca.TestEmailBackend

  def service_module(:smtp), do: Proca.Service.SMTP

  def batch_size(%Org{email_backend: %Service{name: name}}) do
    service_module(name).batch_size()
  end

  def supports_templates?(org = %Org{email_backend: %Service{name: name}}) do
    service_module(name)
    |> apply(:supports_templates?, [org])
  end

  def supports_templates?(org = %Org{email_backend: nil}), do: false

  def list_templates(org = %Org{email_backend: %Service{name: name}}) do
    service_module(name)
    |> apply(:list_templates, [org])
  end

  @doc """
  Delivers list of Email-s using EmailTemplate. Uses Org's email service.

  `:ok` - all went fine
  `{:error, [....]}` - there was some error - could be partial!

  Surprise: you can get  `{:error, [:ok, :ok, :ok]}` with there was some error but adapter decided to drop the email (fatal problem, retry will not help)
  """
  @spec deliver([%Email{}], %Org{}, %EmailTemplate{} | nil) ::
          :ok | {:error, [:ok | {:error, String.t()}]}
  def deliver(recipients, org = %Org{email_backend: %Service{name: name}}, email_template \\ nil) do
    backend = service_module(name)

    emails =
      recipients
      |> Enum.map(fn e ->
        e
        |> determine_sender(org)
        |> prepare_template(email_template)
      end)

    apply(backend, :deliver, [emails, org])
  end

  def make_email(to, custom_id, email_id) do
    make_email(to, custom_id)
    |> Email.put_private(:email_id, email_id)
  end

  def make_email({name, email}, custom_id) do
    Email.new(to: {name, email})
    |> Email.put_private(
      :custom_id,
      case custom_id do
        {type, id} -> format_custom_id(type, id)
        s when is_bitstring(s) -> s
      end
    )
  end

  defp prepare_template(email, nil), do: email

  defp prepare_template(email, tmpl = %EmailTemplate{id: id}) when is_number(id) do
    email
    |> EmailTemplate.render(tmpl)
  end

  # a remote template
  defp prepare_template(email, tmpl = %EmailTemplate{ref: ref}) when not is_nil(ref) do
    email
    |> Email.put_private(:template, tmpl)
    |> prepare_fields()
  end

  # template renderers of Mailjet and friends are happier with a flat list of vars
  defp prepare_fields(%Email{assigns: a} = email) do
    %{email | assigns: flatten_keys(a, "")}
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

      # Sending org uses own email, but sends from another orgs service
      from_email == org.email_from ->
        email
        |> Email.from({from_name, "#{via_username}+#{domain}@#{via_domain}"})

      # Any from email - we will use the username here
      true ->
        email
        |> Email.from({from_name, "#{via_username}+#{username}@#{via_domain}"})
    end
  end

  def parse_custom_id(custom_id) when is_bitstring(custom_id) do
    case String.split(custom_id, ":", trim: true) do
      ["action", id | _] -> {:action, String.to_integer(id)}
      ["mtt", id | _] -> {:mtt, String.to_integer(id)}
      ["user", email | _] -> {:user, email}
      _other -> {nil, nil}
    end
  end

  def format_custom_id(type, id)
      when type in [:action, :mtt] and is_integer(id),
      do: "#{type}:#{id}"

  def format_custom_id(type, id)
      when type in [:user] and is_bitstring(id),
      do: "#{type}:#{id}"
end
