defmodule Proca.Stage.EmailSupporter do
  @moduledoc """
  Processing "stage" that sends thank you emails
  """
  use Broadway

  alias Broadway.Message
  alias Broadway.BatchInfo
  alias Proca.{Org, ActionPage, Action, Contact}
  alias Proca.Repo
  import Ecto.Query
  import Logger

  import Proca.Stage.Support,
    only: [
      ignore: 1,
      ignore: 2,
      failed_partially: 2,
      supporter_link: 3,
      double_opt_in_link: 2,
      too_many_retries?: 1
    ]

  alias Proca.Service.{EmailBackend, EmailMerge, EmailTemplateDirectory}
  alias Swoosh.Email

  def start_for?(%Org{email_backend_id: ebid})
      when is_number(ebid) do
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

  1. Email backend must be configured for the org (Org, AP, )
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
        if send_thank_you?(action_page_id, action_id) and not too_many_retries?(message) do
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
        if send_supporter_confirm?(action_page_id, action_id) and not too_many_retries?(message) do
          message
          |> Message.update_data(fn _ -> action end)
          |> Message.put_batch_key(action_page_id)
          |> Message.put_batcher(:supporter_confirm)
        else
          ignore(message)
        end

      {:ok, _} ->
        warn("EmailSupporter wrk: Invalid message format #{data}")

        ignore(message, "Invalid message format")

      # ignore garbled message
      {:error, reason} ->
        ignore(message, reason)
    end
  end

  @impl true
  def handle_batch(:thank_you, messages, %BatchInfo{batch_key: ap_id}, _) when is_number(ap_id) do
    ap = ActionPage.one(id: ap_id, preload: [org: [email_backend: :org]])
    org = ap.org

    recipients =
      Enum.map(messages, fn m ->
        make(m.data)
        |> add_doi_link()
      end)

    case EmailTemplateDirectory.by_name_reload(org, ap.thank_you_template, ap.locale) do
      {:ok, tmpl} ->
        case EmailBackend.deliver(recipients, org, tmpl) do
          :ok -> messages
          {:error, statuses} -> failed_partially(messages, statuses)
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
    ap = ActionPage.one(id: ap_id, preload: [org: [email_backend: :org]])
    org = ap.org

    tmpl_name = ap.supporter_confirm_template || ap.org.supporter_confirm_template

    recipients =
      Enum.map(messages, fn m ->
        make(m.data)
        |> add_supporter_confirm()
      end)

    case EmailTemplateDirectory.by_name_reload(org, tmpl_name, ap.locale) do
      {:ok, tmpl} ->
        case EmailBackend.deliver(recipients, org, tmpl) do
          :ok -> messages
          {:error, statuses} -> failed_partially(messages, statuses)
        end

      :not_found ->
        Enum.map(
          messages,
          &Message.failed(&1, "Template #{tmpl_name} not found (org #{org.name})")
        )
    end
  end

  defp send_thank_you?(action_page_id, action_id) do
    from(a in Action,
      join: ap in ActionPage,
      on: a.action_page_id == ap.id,
      join: o in Org,
      on: o.id == ap.org_id,
      join: c in Contact,
      on: c.supporter_id == a.supporter_id and c.org_id == o.id,
      where:
        a.id == ^action_id and
          a.with_consent and
          ap.id == ^action_page_id and
          not is_nil(ap.thank_you_template) and
          not is_nil(o.email_backend_id) and
          not is_nil(o.email_from) and
          (not o.doi_thank_you or c.communication_consent)
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
          not is_nil(o.email_from)
    )
    |> Repo.one() != nil
  end

  def make(data) do
    EmailBackend.make_email(
      {get_in(data, ["contact", "firstName"]), get_in(data, ["contact", "email"])},
      {:action, get_in(data, ["actionId"])}
    )
    |> EmailMerge.put_action_message(data)
  end

  defp add_supporter_confirm(email = %Email{assigns: %{ref: ref, action_id: action_id}}) do
    confirm_link = supporter_link(action_id, ref, :confirm)
    reject_link = supporter_link(action_id, ref, :reject)

    EmailMerge.put_assigns(email,
      confirm_link: confirm_link,
      doi_link: confirm_link,
      reject_link: reject_link
    )
  end

  defp add_doi_link(email = %Email{assigns: %{ref: ref, action_id: action_id}}) do
    doi_link = double_opt_in_link(action_id, ref)

    email
    |> EmailMerge.put_assigns(doi_link: doi_link, confirm_link: doi_link)
  end
end
