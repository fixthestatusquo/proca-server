defmodule Proca.Service.SMTP do
  @behaviour Proca.Service.EmailBackend
  alias Proca.{Org, Service}
  alias Swoosh.Email
  alias Swoosh.Adapters.SMTP

  @cacerts :public_key.cacerts_get()

  @impl true
  def supports_templates?(_org) do
    false
  end

  @impl true
  def batch_size(), do: 1

  @impl true
  def list_templates(_org), do: {:ok, []}

  @impl true
  def deliver(emails, %Org{email_backend: srv, name: org_name}) when is_list(emails) do
    conf = config(srv)

    results =
      emails
      |> Enum.map(&put_message_id/1)
      |> Enum.map(&SMTP.deliver(&1, conf))

    Enum.each(results, fn
      {:error, reason} ->
        Sentry.capture_message("Failed to send email by SMTP: #{inspect(reason)}",
          extra: %{org: org_name},
          result: :none
        )

      {:ok, _} ->
        :ok
    end)

    if Enum.all?(results, &match?({:ok, _}, &1)) do
      :ok
    else
      {:error,
       Enum.map(results, fn
         {:ok, _r} -> :ok
         {:error, reason} -> {:error, inspect(reason)}
       end)}
    end
  end

  def deliver(email, org) do
    deliver([email], org)
  end

  def put_message_id(%Email{private: %{custom_id: cid}} = eml) do
    Email.header(eml, "Message-Id", cid)
  end

  def config(%Service{user: u, password: p, host: url}) do
    case URI.parse(url) do
      %{host: h, scheme: scheme, port: port} when h != nil ->
        [
          relay: h,
          username: u,
          password: p,
          port: port,
          auth: :always,
          retries: 2
        ]
        |> put_security(scheme)
    end
  end

  def put_security(opts, scheme) when scheme in ["ssl", "smtps"] do
    host = opts[:relay]

    [{:ssl, true} | opts]
    |> Keyword.update(:port, 465, fn
      nil -> 465
      x -> x
    end)
    |> Keyword.put(:sockopts, [
      verify: :verify_peer,
      cacerts: @cacerts,
      server_name_indication: to_charlist(host)
    ])
  end

  def put_security(opts, "tls") do
    host = opts[:relay]

    [{:tls, :always} | opts]
    |> Keyword.update(:port, 25, fn
      nil -> 25
      x -> x
    end)
    |> Keyword.put(:tls_options, [
      verify: :verify_peer,
      cacerts: @cacerts,
      server_name_indication: to_charlist(host)
    ])
  end

  @impl true
  def handle_bounce(_), do: :ok

  @impl true
  def handle_event(_), do: :ok
end
