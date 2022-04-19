defmodule Proca.Service.SES do
  @moduledoc """
  This module lets you send bulk emails via AWS SES.

  We use bulk emails for crazy throughput!

  For bulk emails you must use templates. We can either create them for each
  batch and then remove, or we can maintain them somehow in AWS (by a hash?),
  but there is a limit of them, so some sort of GC would have to be done.

  We also use the local db mustache tempaltes - then we do not use the bulk send.
  """

  @behaviour Proca.Service.EmailBackend

  alias Proca.Service.EmailTemplate
  alias Proca.Repo
  alias Proca.{Service, Supporter, Action, Org}
  alias Swoosh.Email
  import Logger

  @impl true
  def supports_templates?(_org) do
    false
  end

  @impl true
  def batch_size(), do: 50

  @impl true
  def list_templates(%Org{email_backend: %Service{} = srv} = _org) do
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
        error("UNEXPECTED AWS SES ListTempaltes reply: #{inspect(other)}")
        {:error, "unexpected reply from AWS SES"}
    end
  end

  @impl true
  @doc """
  Warning. The bulk template api is very limited:
  - single sender
  - no headers (no reply-to!)
  """
  def deliver(emails, _org) do
    results =
      emails
      |> Enum.map(fn e ->
        case Swoosh.Adapters.AmazonSES.deliver(e) do
          {:ok, _} -> :ok
          {:error, reason} = e -> e
        end
      end)

    if Enum.all?(results, &(&1 == :ok)) do
      :ok
    else
      {:error, results}
    end
  end

  def send_batch(supporters = [%Supporter{} | _], org, template) do
    org = Repo.preload(org, [:services])

    ExAws.SES.send_bulk_templated_email(
      template.ref,
      "dump@cahoots.pl",
      supporters_to_recipients(supporters)
    )
    |> Service.aws_request(:ses, org)
  end

  def send_batch(actions = [%Action{} | _], org, template) do
    actions
    |> Enum.map(fn a -> a.supporter end)
    |> send_batch(org, template)
  end

  def send_batch([], _, _) do
    :ok
  end

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
end
