
defmodule Proca.Service.Preview do
  @behaviour Proca.Service.EmailBackend

  alias Proca.Org
  alias Swoosh.Email

  def deliver(email, %Org{name: name, email_backend: %{config: config}} = org) do
    email
    |> Swoosh.Email.put_private(:org_name, name)
    |> Swoosh.Adapters.Local.deliver(config)
  end

  def deliver(_email, %Org{} = org) do
    Swoosh.Adapters.Local.deliver(email)
  end

  def list_templates(_org), do: {:ok, []}
  def supports_templates?, do: false
  def name, do: "preview"
end
