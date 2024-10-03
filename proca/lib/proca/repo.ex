defmodule Proca.Repo do
  use Ecto.Repo,
    otp_app: :proca,
    adapter: Ecto.Adapters.Postgres

  alias Proca.Server.Notify

  def insert_and_notify(changeset, opts \\ []) do
    {nopts, opts} = notify_opts(opts)

    case insert(changeset, opts) do
      {:ok, record} ->
        Notify.created(record, nopts)
        {:ok, record}

      {:error, _errors} = e ->
        e
    end
  end

  def update_and_notify(changeset, opts \\ []) do
    {nopts, opts} = notify_opts(opts)

    case update(changeset, opts) do
      {:ok, record} ->
        Notify.updated(record, nopts)
        {:ok, record}

      {:error, _errors} = e ->
        e
    end
  end

  def insert_and_notify!(changeset, opts \\ []) do
    {nopts, opts} = notify_opts(opts)
    record = insert!(changeset, opts)
    Notify.created(record, nopts)
    record
  end

  def update_and_notify!(changeset, opts \\ []) do
    {nopts, opts} = notify_opts(opts)
    record = update!(changeset, opts)
    Notify.updated(record, nopts)
    record
  end

  def transaction_and_notify(%Ecto.Multi{} = multi, operation_name, opts \\ []) do
    {nopts, opts} = notify_opts(opts)

    case transaction(multi) do
      {:ok, result} ->
        Notify.multi(operation_name, result, nopts)
        {:ok, result}

      {:error, _error} = e ->
        e

      {:error, _failed, error, _so_far} = e ->
        if opts[:all_error] do
          e
        else
          {:error, error}
        end
    end
  end

  def delete_and_notify(record, opts \\ []) do
    {nopts, opts} = notify_opts(opts)

    case delete(record, opts) do
      {:ok, record} ->
        Notify.deleted(record, nopts)
        {:ok, record}

      {:error, _errors} = e ->
        e
    end
  end

  def delete_and_notify!(changeset, opts \\ []) do
    {nopts, opts} = notify_opts(opts)
    record = delete!(changeset, opts)
    Notify.deleted(record, nopts)
    record
  end

  defp notify_opts(opts) do
    {auth, opts} = Keyword.pop(opts, :auth)
    {id, opts} = Keyword.pop(opts, :id)

    nopts =
      []
      |> maybe_add(:auth, auth)
      |> maybe_add(:id, id)

    {nopts, opts}
  end

  defp maybe_add(acc, _key, nil), do: acc
  defp maybe_add(acc, key, value), do: [{key, value} | acc]
end
