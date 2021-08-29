defmodule Proca.TestEmailBackend do 
  @behaviour Proca.Service.EmailBackend

  alias Proca.Service.{EmailTemplate, EmailBackend}
  alias Bamboo.Email
  use GenServer

  @impl true 
  def init(opts) do
    {:ok, %{opts: opts, mbox: %{}}}
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  # GenServer server
  @impl true 
  def handle_call(:opts, _from, st = %{opts: opts}), do: {:reply, st, opts}

  @impl true 
  def handle_call({:send_to, address, email}, _from, st = %{mbox: mbox}) do 
    address = case address do 
      {_name, email_part} -> email_part
      email_part when is_bitstring(email_part) -> email_part
    end

    mbox = mbox 
    |> Map.update(address, [email], fn e -> [email|e] end ) 

    {:reply, :ok, %{st | mbox: mbox}}
  end

  @impl true 
  def handle_call({:mailbox, address}, _from, s = %{mbox: mbox}) do
    {:reply,  Map.get(mbox, address, nil), s}
  end

  # GenServer client
  def opts(), do: GenServer.call(__MODULE__, :opts)

  def send_to(address, email), do: GenServer.call(__MODULE__, {:send_to, address, email})

  def mailbox(address), do: GenServer.call(__MODULE__, {:mailbox, address})


  @impl true
  def supports_templates?(_org) do
    true
  end

  @impl true
  def list_templates(_srv) do
    t = [
      %EmailTemplate{ref: "ref:thankyouemail", name: "thank_you", subject: "Thank you email", html: "Thank you body"},
      %EmailTemplate{ref: "ref:addpartner", name: "add_partner", subject: "You are invited to join a campaign", html: "Invite body"},
      %EmailTemplate{ref: "ref:launchpage", name: "launch_page", subject: "Partner request", html: "Can I join campaign?"}
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
  def put_recipients(email, recipients) do
    email
    |> Email.to([])
    |> Email.cc([])
    |> Email.bcc(
      Enum.map(
        recipients,
        fn %{first_name: name, email: eml} -> {name, eml} end
      )
    )
    |> Email.put_private(:fields, Enum.map(recipients, fn r -> {r.email, r.fields} end) |> Map.new() )
  end

  @impl true
  def put_template(email, %EmailTemplate{ref: ref, subject: sub, html: body}) do
    %{ email | subject: sub, html_body: body}
    |> Map.update(:private, %{}, &Map.put(&1, :template_ref,ref))
  end

  @impl true
  def put_reply_to(email, reply_to_email) do
    email
    |> Email.put_header("Reply-To", reply_to_email)
  end

  @impl true
  def deliver(email, _org) do
    for address <- email.bcc do 
      send_to(address, email)
    end
  end
end

