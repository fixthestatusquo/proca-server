
defmodule Proca.Service.Preview do
  @behaviour Proca.Service.EmailBackend

  alias Proca.Org
  alias Swoosh.Email

  def deliver(email, %Org{name: name, email_backend: %{config: config}} = org) do
    email
    |> Swoosh.Email.put_private(:org_name, name)
    |> Swoosh.Adapters.Local.deliver(config)
  end

  def deliver(email, %Org{} = org) do
    # Provide default config when none is available from the org, it should go to the common mailbox?
    default_config = []
    Swoosh.Adapters.Local.deliver(default_config, email)
  end

  def list_templates(_org), do: {:ok, []}
  def supports_templates?, do: false
  def name, do: "preview"
end
