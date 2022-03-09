defmodule Proca.TestEmailBackend do
  @moduledoc """
  A fake in memory email backend.

  Collects emails in a map:
  - map( recipient_email_string -> [Email] )

  Usage: 
  ```
  use Proca.TestEmailBackend
  ```

  XXX try to use the Memory adapter from Swoosh? Challenge: can we empty its storage between test runs?
  """

  # Test part
  use ExUnit.CaseTemplate

  alias Swoosh.Email

  def test_email_backend(context) do
    io = Proca.Org.one([preload: [:services, :email_backend, :template_backend]] ++ [:instance])
    backend = Proca.Factory.insert(:email_backend, org: io)

    Ecto.Changeset.change(io, email_from: "no-reply@" <> backend.host)
    |> Ecto.Changeset.put_assoc(:services, [backend])
    |> Proca.Org.put_service(backend)
    |> Proca.Repo.update!()

    {:ok, email_backend_pid} = Proca.TestEmailBackend.start_link([])

    on_exit(:stop_email_backend, fn ->
      Process.exit(email_backend_pid, :kill)
    end)

    context
    |> Map.put(:email_backend, email_backend_pid)
  end

  using do
    quote do
      import Proca.TestEmailBackend,
        only: [
          test_email_backend: 1,
          mailbox: 1
        ]

      setup :test_email_backend
    end
  end

  # Server part
  use GenServer
  @impl true
  def init(opts) do
    {:ok, %{opts: opts, mbox: %{}}}
  end

  @doc """
  Start the gen server, killing an old one if it's still around (it sometimes happen)
  Try two times.
  """
  def start_link(opts) do
    case GenServer.start_link(__MODULE__, opts, name: __MODULE__) do
      {:ok, _pid} = p ->
        p

      {:error, {:already_started, pid}} = e ->
        Process.exit(pid, :kill)

        opts = Keyword.update(opts, :retry, 1, &(&1 + 1))

        if opts[:retry] < 3 do
          :timer.sleep(500)
          start_link(opts)
        else
          e
        end
    end
  end

  # GenServer server
  @impl true
  def handle_call(:opts, _from, st = %{opts: opts}), do: {:reply, st, opts}

  @impl true
  def handle_call({:send_to, address, email}, _from, st = %{mbox: mbox}) do
    address =
      case address do
        {_name, email_part} -> email_part
        email_part when is_bitstring(email_part) -> email_part
      end

    mbox =
      mbox
      |> Map.update(address, [email], fn e -> [email | e] end)

    {:reply, :ok, %{st | mbox: mbox}}
  end

  @impl true
  def handle_call({:mailbox, address}, _from, s = %{mbox: mbox}) do
    m = Map.get(mbox, address, [])
    {:reply, m, s}
  end

  # GenServer client
  def opts(), do: GenServer.call(__MODULE__, :opts)

  def send_to(address, email), do: GenServer.call(__MODULE__, {:send_to, address, email})

  def mailbox(address), do: GenServer.call(__MODULE__, {:mailbox, address})

  # Email Backend part
  @behaviour Proca.Service.EmailBackend
  alias Proca.Service.{EmailTemplate}
  alias Swoosh.Email
  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def batch_size(), do: 5

  @impl true
  def list_templates(_srv) do
    t = [
      %EmailTemplate{
        ref: "ref:thankyouemail",
        name: "thank_you",
        subject: "Thank you email",
        html: "Thank you body"
      },
      %EmailTemplate{
        ref: "ref:addpartner",
        name: "add_partner",
        subject: "You are invited to join a campaign",
        html: "Invite body"
      },
      %EmailTemplate{
        ref: "ref:launchpage",
        name: "launch_page",
        subject: "Partner request",
        html: "Can I join campaign?"
      },
      %EmailTemplate{
        ref: "ref:addstaffer",
        name: "add_staffer",
        subject: "Invitation to org",
        html: "Welcome to our team"
      },
      %EmailTemplate{
        ref: "ref:user_confirm_email",
        name: "user_confirm_email",
        subject: "Confirm your email",
        html: "Click here"
      },
      %EmailTemplate{
        ref: "ref:user_reset_password",
        name: "user_reset_password",
        subject: "Reset password",
        html: "Click here"
      },
      %EmailTemplate{
        ref: "ref:user_change_email",
        name: "user_change_email",
        subject: "Confirm change of email",
        html: "Click here"
      }
    ]

    {:ok, t}
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
  def deliver(emails, _org) do
    for e <- emails do
      t = e.private[:template]

      e =
        if t != nil do
          e
          |> Email.put_provider_option(:template_ref, t.ref)
          |> Email.put_provider_option(:custom_id, e.private[:custom_id])
          |> Email.subject(t.subject)
          |> Email.text_body(t.text)
          |> Email.html_body(t.html)
        else
          e
        end

      [to | _] = e.to
      send_to(to, e)
    end

    :ok
  end

  @impl true
  def handle_bounce(type) do
  end
end
