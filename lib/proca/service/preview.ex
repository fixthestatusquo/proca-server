defmodule Proca.Service.Email.Preview do
  @behaviour Proca.Service.EmailBackend

  alias Proca.Org
  alias Swoosh.Email

  @impl true
  def batch_size, do: 25

  @impl true
  def deliver(emails, org) when is_list(emails) do
    Enum.each(emails, fn email -> deliver(email, org) end)
  end

  def deliver(email, %Org{name: name, email_backend: %{config: config}} = _org) do
    email = Email.put_private(email, :org_name, name)

    log_email_preview(email)
    Proca.Service.Preview.OrgStorage.push(email)

    Swoosh.Adapters.Local.deliver(email, config)
  end

  def deliver(email, %Org{} = _org) do
    default_config = []

    log_email_preview(email)
    Proca.Service.Preview.OrgStorage.push(email)

    Swoosh.Adapters.Local.deliver(email, default_config)
  end

  defp log_email_preview(emails) when is_list(emails) do
    Enum.each(emails, &log_email_preview/1)
  end

  defp log_email_preview(email) do
    IO.puts("\n===== Email Preview =====")
    IO.puts("From: #{format_addresses(email.from)}")
    IO.puts("To: #{format_addresses(email.to)}")
    IO.puts("Subject: #{email.subject}")
    IO.puts("=========================\n")
  end

  def format_addresses(nil), do: "(none)"

  def format_addresses({name, email}) when is_binary(name) and is_binary(email) do
    # Simple sanitization: if email contains invalid characters, just quote it or fallback to inspect
    if String.contains?(email, [" ", ",", "<", ">"]) do
      "#{name} <\"#{email}\">"
    else
      "#{name} <#{email}>"
    end
  end

  def format_addresses(address) when is_binary(address), do: address

  def format_addresses(list) when is_list(list) do
    list
    |> Enum.map_join(", ", &format_addresses/1)
  end

  @impl true
  def list_templates(_org), do: {:ok, []}

  def name, do: "preview"

  @impl true
  def handle_bounce(_), do: :ok

  @impl true
  def handle_event(_), do: :ok

  @impl true
  def supports_templates?(_), do: false
end
