defmodule Proca.Confirm.ConfirmAction do 
  alias Proca.Action 
  alias Proca.Confirm
  @behaviour Confirm.Operation
  import Proca.Changeset 
  import Proca.Repo

  def create(%Action{id: id}) do 
    %{
      operation: :confirm_action,
      subject_id: id
    } |> Confirm.create()
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
  def email_fields(_), do: %{}
end
