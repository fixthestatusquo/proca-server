defmodule Proca.Confirm.ConfirmAction do
  alias Proca.{Action, Confirm}
  @behaviour Confirm.Operation
  import Proca.Repo

  def changeset(%Action{id: id}) do
    %{
      operation: :confirm_action,
      subject_id: id
    }
  end

  @impl true
  def run(%Confirm{operation: :confirm_action, subject_id: id}, :confirm, _) do
    case get(Action, id) |> Action.confirm() do
      {:ok, _} -> :ok
      {:noop, _} -> :ok
      {:error, _} = e -> e
    end
  end

  @impl true
  def run(%Confirm{operation: :confirm_action, subject_id: id}, :reject, _) do
    case get(Action, id) |> Action.reject() do
      {:ok, _} -> :ok
      {:noop, _} -> :ok
      {:error, _} = e -> e
    end
  end

  @impl true
  def email_template(_), do: "confirm_action"

  @impl true
  def notify_fields(_), do: %{}
end
