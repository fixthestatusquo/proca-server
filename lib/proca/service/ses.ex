defmodule Proca.Service.SES do
  @moduledoc """
  This module lets you send bulk emails via AWS SES.

  We use bulk emails for crazy throughput!

  For bulk emails you must use templates. We can either create them for each
  batch and then remove, or we can maintain them somehow in AWS (by a hash?),
  but there is a limit of them, so some sort of GC would have to be done.

  We also use the local db mustache templates - then we do not use the bulk send.
  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.Service.EmailTemplate
  alias Proca.{Service, Org, Supporter, Target}
  alias Swoosh.Email
  import Logger
  import Proca.Service.EmailBackend, only: [parse_custom_id: 1]

  # our id travels both as a header and as SES tags: identity notifications only
  # carry headers, configuration set events only carry tags
  @id_header "X-Proca-Id"

  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def batch_size(), do: 50

  @impl true
  def list_templates(%Org{email_backend: %Service{} = srv}) do
    list_templates_page(srv)
  end

  defp list_templates_page(srv, lst \\ [], next_token \\ nil) do
    opts =
      if is_nil(next_token) do
        []
      else
        [next_token: next_token]
      end

    data =
      ExAws.SES.list_templates(opts)
      |> Service.aws_request(srv)

    make_template = fn %{"Name" => name} -> %EmailTemplate{name: name, ref: name} end

    case data do
      {:ok,
       %{
         "ListTemplatesResponse" => %{
           "ListTemplatesResult" => %{
             "NextToken" => nt,
             "TemplatesMetadata" => templates_meta
           }
         }
       }} ->
        lst2 = lst ++ Enum.map(templates_meta, make_template)

        if is_nil(nt) do
          # no paging
          {:ok, lst2}
        else
          list_templates_page(srv, lst2, nt)
        end

      other ->
        error("UNEXPECTED AWS SES ListTemplates reply org_id=#{srv.org_id}: #{inspect(other)}")
        {:error, "unexpected reply from AWS SES"}
    end
  end

  @impl true
  @doc """
  Warning. The bulk template api is very limited:
  - single sender
  - no headers (no reply-to!)
  """
  def deliver(emails, %Org{email_backend: srv}) when is_list(emails) do
    results =
      emails
      |> Enum.map(fn e ->
        case Swoosh.Adapters.AmazonSES.deliver(put_custom_id(e), config(srv)) do
          {:ok, _} -> :ok
          {:error, _reason} = e -> e
        end
      end)

    if Enum.all?(results, &(&1 == :ok)) do
      :ok
    else
      {:error, results}
    end
  end

  def deliver(email, org) do
    deliver([email], org)
  end

  defp config(%Service{name: :ses, user: access_key, password: secret, host: region}) do
    [region: region, access_key: access_key, secret: secret]
  end

  @doc false
  def put_custom_id(%Email{private: %{custom_id: cid}} = email) when is_bitstring(cid) do
    case parse_custom_id(cid) do
      # SES tag values only allow [A-Za-z0-9_-], so "action:1" is split into two tags
      # https://docs.aws.amazon.com/ses/latest/APIReference/API_MessageTag.html
      {type, id} when type in [:action, :mtt] ->
        email
        |> Email.header(@id_header, cid)
        |> Email.put_provider_option(:tags, [
          %{name: "proca_type", value: Atom.to_string(type)},
          %{name: "proca_id", value: Integer.to_string(id)}
        ])

      _ ->
        email
    end
  end

  def put_custom_id(email), do: email

  def to_destionation(%Email{to: to, assigns: assigns}) do
    %{
      destination: %{
        to: Enum.map(to, &elem(&1, 1)),
        cc: [],
        bcc: []
      },
      replacement_template_data: assigns
    }
  end

  def supporters_to_recipients(supporters) do
    supporters
    |> Enum.map(fn s ->
      %{
        destination: %{
          to: [s.email],
          cc: [],
          bcc: []
        },
        replacement_template_data: %{
          "firstName" => s.first_name,
          "email" => s.email
        }
      }
    end)
  end

  def event_type(report), do: report["eventType"] || report["notificationType"]

  # tags in configuration set events, header in identity notifications (see put_custom_id)
  def custom_id(%{"tags" => %{"proca_type" => [type | _], "proca_id" => [id | _]}}),
    do: "#{type}:#{id}"

  def custom_id(%{"headers" => headers}) when is_list(headers) do
    Enum.find_value(headers, fn
      %{"name" => name, "value" => value} when is_binary(name) ->
        if String.downcase(name) == String.downcase(@id_header), do: value

      _ ->
        nil
    end)
  end

  def custom_id(_mail), do: nil

  @impl true
  def handle_bounce(%{"mail" => mail} = report) do
    type = event_type(report)
    :telemetry.execute([:mailer, :ses, :bounces], %{count: 1}, %{reason: type})

    case {custom_id(mail), bounced(type, report)} do
      # sent without our id, eg. to a user
      {nil, _} ->
        :ok

      {_, []} ->
        warn_malformed(report)

      {cid, recipients} ->
        case parse_custom_id(cid) do
          # the supporter is the only recipient
          {:action, id} -> recipients |> hd() |> Map.put(:id, id) |> Supporter.handle_bounce()
          {:mtt, id} -> Enum.each(recipients, &Target.handle_bounce(Map.put(&1, :id, id)))
          _ -> {:error, :invalid_custom_id}
        end
    end
  end

  @impl true
  def handle_bounce(report), do: warn_malformed(report)

  @impl true
  def handle_event(%{"mail" => _} = report) do
    case event_type(report) do
      nil ->
        warn_malformed(report)

      type ->
        :telemetry.execute([:mailer, :ses, :events], %{count: 1}, %{reason: type})
    end
  end

  @impl true
  def handle_event(report), do: warn_malformed(report)

  # params for Supporter/Target.handle_bounce, one per recipient, without the id
  # https://docs.aws.amazon.com/ses/latest/dg/event-publishing-retrieving-sns-contents.html
  defp bounced("Bounce", %{"bounce" => %{} = bounce}) do
    # Transient and Undetermined may still be delivered later
    soft = bounce["bounceType"] != "Permanent"

    for %{"emailAddress" => email} = r <- bounce["bouncedRecipients"] || [] do
      %{email: email, reason: :bounce, soft: soft, error: r["diagnosticCode"]}
    end
  end

  defp bounced("Complaint", %{"complaint" => %{} = complaint}) do
    for %{"emailAddress" => email} <- complaint["complainedRecipients"] || [] do
      %{email: email, reason: :spam, error: complaint["complaintFeedbackType"]}
    end
  end

  defp bounced("Reject", %{"reject" => %{} = reject, "mail" => mail}) do
    for email <- mail["destination"] || [] do
      %{email: email, reason: :blocked, error: reject["reason"]}
    end
  end

  defp bounced(_type, _report), do: []

  defp warn_malformed(report) do
    warn("Malformed SES report: #{inspect(report)}")
  end
end
