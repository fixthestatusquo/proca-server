defmodule Proca.Service.Supabase do
  @moduledoc """
  Currently, a storage service
  """
  alias Supabase.Storage

  alias Proca.Service

  def connect(%Service{name: :supabase, password: key, host: url}) do
    Supabase.Connection.new(url, key)
  end

  def fetch(%Service{} = service, key) do
    with [bucket | filename] <- String.split(key, "/") do
      filename = Enum.join(filename, "/")

      res =
        connect(service)
        |> Storage.from(bucket)
        |> Storage.download(filename)

      case res do
        {:ok, _} -> res
        {:error, err_obj} -> {:error, normalize_error(err_obj)}
      end
    else
      [] -> {:error, :invalid_filename}
    end
  end

  def normalize_error(%{"error" => "Not found"}), do: :not_found
  def normalize_error(%{"error" => "Invalid JWT"}), do: :not_authenticated

  def normalize_error(e) do
    Sentry.capture_message("Other Supabase.Storage error: #{inspect(e)}", result: :none)

    :other
  end
end
