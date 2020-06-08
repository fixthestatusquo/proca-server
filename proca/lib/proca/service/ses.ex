defmodule Proca.Service.SES do
  alias Proca.Service.EmailTemplate
  alias Proca.Repo
  alias Proca.{Service, Supporter, Action}

  @moduledoc """
  This module lets you send bulk emails via AWS SES.

  We use bulk emails for crazy throughput! 

  For bulk emails you must use templates. We can either create them for each
  batch and then remove, or we can maintain them somehow in AWS (by a hash?),
  but there is a limit of them, so some sort of GC would have to be done.

  We could also have some other system (for instance WpMailTemplate Server that
  fetches template, refreshes then every once in a while, and pushes them to SES.)

  What sort of emails do we have?
  - thank you emails (one per page)
  - supporter confirm email (one per org?)

  ActioPage.thank_you_template_ref (can be null)

  MVP:
  - send_batch method that creates a template always, (maybe overwriting?)
  - send_batch then sends the batch
  - and does not care about the template
  """

  @doc """
  XXX this method should later keep track of whether EmailTemplate was changed or not...
  """
  def create_template(org, %EmailTemplate{ref: ref, subject: subject, html: html, text: text}) do
    ExAws.SES.create_template(ref, subject, html, text)
    |> Service.aws_request(:ses, org)
  end

  def send_batch([%Supporter{} | _] = supporters, org, template) do
    org = Repo.preload(org, [:services])
    create_template(org, template)

    ExAws.SES.send_bulk_templated_email(
      template.ref,
      "dump@cahoots.pl",
      supporters_to_recipients(supporters))
    |> Service.aws_request(:ses, org)
  end


  def send_batch([%Action{} | _] = actions, org, template) do
    actions
    |> Enum.map(fn a -> a.supporter end)
    |> send_batch(org, template)
  end

  def send_batch([], _, _) do
    :ok
  end

  def supporters_to_recipients(supporters) do
    supporters
    |> Enum.map(fn s -> %{
                        destination: %{
                          to: [s.email],
                          cc: [], bcc: []
                        },
                        replacement_template_data: %{
                          "firstName" => s.first_name,
                          "email" => s.email
                        }
                    } end)
  end
end
