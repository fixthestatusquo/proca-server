defmodule Proca.Stage.EmailSupporter do
  @moduledoc """
  Processing "stage" that sends thank you emails
  """
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Org, ActionPage, Action, Supporter}
  alias Proca.Repo
  import Ecto.Query
  import Logger
  import Proca.Stage.Support, only: [ignore: 1, ignore: 2, supporter_link: 3]

  alias Proca.Service.{EmailBackend, EmailRecipient, EmailTemplate, EmailTemplateDirectory}

  def start_for?(%Org{email_backend_id: ebid, template_backend_id: tbid}) when is_number(ebid) and is_number(tbid) do
    true
  end

  def start_for?(_), do: false

  def start_link(org = %Org{id: org_id}) do
    Broadway.start_link(__MODULE__,
      name: String.to_atom(Atom.to_string(__MODULE__) <> ".#{org_id}"),
      producer: [
        module: Proca.Pipes.Topology.broadway_producer(org, "email.supporter"),
        concurrency: 1
      ],
      processors: [
        default: [
          concurrency: 1
        ]
      ],
      batchers: [
        thank_you: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 1
        ],
        opt_in: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 1
        ]
        # noop: [
        #   batch_size: 1,
        #   concurrency: 1
        # ]
      ]
    )
  end

  @doc """
  Not all actions generate thank you emails.

  1. Email and template backend must be configured for the org (Org, AP, )
  2. ActionPage's email template must be set [present in JSON]. (XXX Or fallback to org one?)
  """

  @impl true
  def handle_message(_, message = %Message{data: data}, _) do
    case JSON.decode(data) do
      {:ok,
      %{
        "stage" => "deliver",
        "actionPageId" => action_page_id,
        "actionId" => action_id
        } = action
      } ->
        if send_thank_you?(action_page_id, action_id) do
          message
          |> Message.update_data(fn _ -> action end)
          |> Message.put_batch_key(action_page_id)
          |> Message.put_batcher(:thank_you)
        else
          ignore message
        end

      {:ok,
       %{
         "stage" => "supporter_confirm",
         "orgId" => org_id,
         "actionId" => action_id
       } = action
      } ->
        if send_opt_in?(org_id, action_id) do
          message
          |> Message.update_data(fn _ -> action end)
          |> Message.put_batcher(:opt_in)
        else
          ignore message
        end

      # ignore garbled message
      {:error, reason} ->
        ignore message, reason
    end
  end

  @impl true
  def handle_batch(:thank_you, messages, %BatchInfo{batch_key: ap_id}, _) do
    ap = ActionPage.one(id: ap_id, preload: [org: [[email_backend: :org], :template_backend]])

    recipients = Enum.map(messages, fn m -> EmailRecipient.from_action_data(m.data) end)

    tmpl = %EmailTemplate{ref: ap.thank_you_template_ref}

    try do
      EmailBackend.deliver(recipients, ap.org, tmpl)
      messages
    rescue
      x in EmailBackend.NotDeliverd ->
        error("Failed to send email batch #{x.message}")
        Enum.map(messages, &Message.failed(&1, x.message))
    end
  end

  @impl true
  def handle_batch(:opt_in, [fm|_] = messages, _, _) do
    org_id = fm.data["orgId"]

    org = from(org in Org,
      where: org.id == ^org_id,
      preload: [[email_backend: :org], [template_backend: :org]]
    )
    |> Repo.one()

    recipients = Enum.map(messages, fn m -> 
      EmailRecipient.from_action_data(m.data) 
      |> add_supporter_confirm(m.data)
    end)

    tmpl_name = org.email_opt_in_template || org.template_backend.org.email_opt_in_template
    case EmailTemplateDirectory.ref_by_name_reload(org, tmpl_name) do 
      {:ok, tmpl_ref} -> 
        tmpl = %EmailTemplate{ref: tmpl_ref}

        try do
          EmailBackend.deliver(recipients, org, tmpl)
          messages
        rescue
          x in EmailBackend.NotDeliverd ->
            error("Failed to send email batch #{x.message}")
          Enum.map(messages, &Message.failed(&1, x.message))
        end

      :not_found -> 
        Enum.map(messages, &Message.failed(&1, "Template #{tmpl_name} not found (org #{org.name})"))

      :not_configured -> 
        Enum.map(messages, &Message.failed(&1, "Template #{tmpl_name} backend not configured (org #{org.name})"))
    end
  end

  # @impl true
  # def handle_batch(:noop, messages, _, _) do
  #   messages
  #   |> Message.ack_immediately()
  # end

  defp send_thank_you?(action_page_id, action_id) do
    from(a in Action,
      join: ap in ActionPage,
      on: a.action_page_id == ap.id,
      join: o in Org,
      on: o.id == ap.org_id,
      where:
        a.id == ^action_id and
        a.with_consent and
        ap.id == ^action_page_id and
          not is_nil(ap.thank_you_template_ref) and
          not is_nil(o.email_backend_id) and
          not is_nil(o.template_backend_id) and
          not is_nil(o.email_from)
    )
    |> Repo.one() != nil
  end

  # The message was already queued for this optin, so lets check
  # for sending invariants, that is, template existence
  defp send_opt_in?(org_id, action_id) do
    action = Repo.get(Action, action_id)

    if action.with_consent do
      org = Repo.get(Org, org_id)

      is_bitstring(org.email_opt_in_template) and
      is_number(org.email_backend_id) and
      is_number(org.template_backend_id)
    else
      error("Should not happen: action with no consent in supporter_confirm queue: #{action_id}")
      false
    end
  end

  defp add_action_confirm(rcpt = %EmailRecipient{}, action_id) do 
    confirm = Proca.Confirm.ConfirmAction.create(%Action{id: action_id})
    EmailRecipient.put_confirm(rcpt, confirm)
  end

  defp add_supporter_confirm(rcpt = %EmailRecipient{}, data) do 
    action_id = data["actionId"]
    ref = data["contact"]["ref"]
    EmailRecipient.put_fields(rcpt, [
      confirm_link: supporter_link(action_id, ref, :confirm),
      reject_link: supporter_link(action_id, ref, :reject)
    ])
  end
end
