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

  def start_for?(%Org{email_backend_id: ebid, template_backend_id: tbid})
      when is_number(ebid) and is_number(tbid) do
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
        supporter_confirm: [
          batch_size: 5,
          batch_timeout: 10_000,
          concurrency: 1
        ]
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
       } = action} ->
        if send_thank_you?(action_page_id, action_id) do
          message
          |> Message.update_data(fn _ -> action end)
          |> Message.put_batch_key(action_page_id)
          |> Message.put_batcher(:thank_you)
        else
          ignore(message)
        end

      {:ok,
       %{
         "stage" => "supporter_confirm",
         "actionPageId" => action_page_id,
         "actionId" => action_id
       } = action} ->
        if send_supporter_confirm?(action_page_id, action_id) do
          message
          |> Message.update_data(fn _ -> action end)
          |> Message.put_batch_key(action_page_id)
          |> Message.put_batcher(:supporter_confirm)
        else
          case confirm_supporter(action_id) do
            :ok ->
              ignore(message)

            {:error, e} ->
              Message.failed(
                message,
                "Cannot auto-confirm supporter (action id #{action_id}): #{e}"
              )
          end
        end

      # ignore garbled message
      {:error, reason} ->
        ignore(message, reason)
    end
  end

  @impl true
  def handle_batch(:thank_you, messages, %BatchInfo{batch_key: ap_id}, _) when is_number(ap_id) do
    ap = ActionPage.one(id: ap_id, preload: [org: [[email_backend: :org], :template_backend]])
    org = ap.org

    recipients = Enum.map(messages, fn m -> EmailRecipient.from_action_data(m.data) end)

    case EmailTemplateDirectory.ref_by_name_reload(org, ap.thank_you_template) do
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
        Enum.map(
          messages,
          &Message.failed(&1, "Template #{ap.thank_you_template} not found (org #{org.name})")
        )

      :not_configured ->
        Enum.map(
          messages,
          &Message.failed(
            &1,
            "Template #{ap.thank_you_template} backend not configured (org #{org.name})"
          )
        )
    end
  end

  @impl true
  def handle_batch(:supporter_confirm, messages, %BatchInfo{batch_key: ap_id}, _)
      when is_number(ap_id) do
    ap = ActionPage.one(id: ap_id, preload: [org: [[email_backend: :org], :template_backend]])
    org = ap.org

    tmpl_name = ap.supporter_confirm_template || ap.org.supporter_confirm_template

    recipients =
      Enum.map(messages, fn m ->
        EmailRecipient.from_action_data(m.data)
        |> add_supporter_confirm(m.data)
      end)

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
        Enum.map(
          messages,
          &Message.failed(&1, "Template #{tmpl_name} not found (org #{org.name})")
        )

      :not_configured ->
        Enum.map(
          messages,
          &Message.failed(&1, "Template #{tmpl_name} backend not configured (org #{org.name})")
        )
    end
  end

  defp confirm_supporter(action_id) do
    alias Proca.Server.Processing
    action = Action.one(id: action_id, preload: [:supporter])

    case Supporter.confirm(action.supporter) do
      {:ok, sup2} -> Processing.process_async(%{action | supporter: sup2})
      {:noop, _} -> :ok
      {:error, msg} -> {:error, msg}
    end
  end

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
          not is_nil(ap.thank_you_template) and
          not is_nil(o.email_backend_id) and
          not is_nil(o.template_backend_id) and
          not is_nil(o.email_from)
    )
    |> Repo.one() != nil
  end

  # The message was already queued for this optin, so lets check
  # for sending invariants, that is, template existence
  defp send_supporter_confirm?(action_page_id, action_id) do
    from(a in Action,
      join: ap in ActionPage,
      on: a.action_page_id == ap.id,
      join: o in Org,
      on: o.id == ap.org_id,
      where:
        a.id == ^action_id and
          a.with_consent and
          ap.id == ^action_page_id and
          (not is_nil(o.supporter_confirm_template) or
             not is_nil(ap.supporter_confirm_template)) and
          not is_nil(o.email_backend_id) and
          not is_nil(o.template_backend_id) and
          not is_nil(o.email_from)
    )
    |> Repo.one() != nil
  end

  ## XXX use this ?
  defp add_action_confirm(rcpt = %EmailRecipient{}, action_id) do
    confirm =
      Proca.Confirm.ConfirmAction.changeset(%Action{id: action_id})
      |> Proca.Confirm.insert!()

    EmailRecipient.put_confirm(rcpt, confirm)
  end

  defp add_supporter_confirm(rcpt = %EmailRecipient{ref: ref}, data) do
    action_id = data["actionId"]

    EmailRecipient.put_fields(rcpt,
      confirm_link: supporter_link(action_id, ref, :confirm),
      reject_link: supporter_link(action_id, ref, :reject)
    )
  end
end
