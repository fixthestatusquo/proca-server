defmodule Proca.Service.SMTP do
  @behaviour Proca.Service.EmailBackend
  alias Proca.{Org, Service}
  alias Swoosh.Email
  alias Swoosh.Adapters.SMTP

  @impl true
  def supports_templates?(_org) do
    false
  end

  @impl true
  def batch_size(), do: 1

  @impl true
  def list_templates(_org), do: {:ok, []}

  @impl true
  def deliver(emails, %Org{email_backend: srv, name: org_name}) do
    conf = config(srv)

    results =
      emails
      |> Enum.map(&put_message_id/1)
      |> Enum.map(&SMTP.deliver(&1, conf))

    Enum.each(results, fn
      {:ok, _} ->
        :ok

      {:error, reason} ->
        Sentry.capture_message("Failed to send email by SMTP: #{inspect(reason)}",
          extra: %{org: org_name},
          result: :none
        )
    end)

    :ok
    # XXX not clear which errors are retryable?
    # if Enum.all?(results, & &1 == :ok) do
    #   :ok
    # else
    #   {:error, Enum.map(results, fn
    #       {:ok, _r} -> :ok
    #       {:error, reason} -> {:error, inspect(reason)}
    #     end)}
    # end
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

  def put_security(opts, "ssl") do
    [{:ssl, true} | opts]
    |> Keyword.update(:port, 587, fn
      nil -> 587
      x -> x
    end)

    # set if not set
  end

  def put_security(opts, "tls") do
    [{:tls, :always} | opts]
    |> Keyword.update(:port, 25, fn
      nil -> 25
      x -> x
    end)

    # set if not set
  end
end
