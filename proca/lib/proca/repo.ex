defmodule Proca.Repo do
  use Ecto.Repo,
    otp_app: :proca,
    adapter: Ecto.Adapters.Postgres

  alias Proca.Server.Notify

  def insert_and_notify(changeset, opts \\ []) do
    case insert(changeset, opts) do
      {:ok, record} ->
        Notify.created(record)
        {:ok, record}

      {:error, _errors} = e ->
        e
    end
  end

  def update_and_notify(changeset, opts \\ []) do
    case update(changeset, opts) do
      {:ok, record} ->
        Notify.updated(record)
        {:ok, record}

      {:error, _errors} = e ->
        e
    end
  end

  def insert_and_notify!(changeset, opts \\ []) do
    record = insert!(changeset, opts)
    Notify.created(record)
    record
  end

  def update_and_notify!(changeset, opts \\ []) do
    record = update!(changeset, opts)
    Notify.updated(record)
    record
  end

  def transaction_and_notify(%Ecto.Multi{} = multi, operation_name, opts \\ []) do
    case transaction(multi) do
      {:ok, result} ->
        Notify.multi(operation_name, result)
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
    case delete(record, opts) do
      {:ok, record} ->
        Notify.deleted(record)
        {:ok, record}

      {:error, _errors} = e ->
        e
    end
  end

  def delete_and_notify!(changeset, opts \\ []) do
    record = delete!(changeset, opts)
    Notify.deleted(record)
    record
  end
end
