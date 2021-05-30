defmodule Proca.Confirm.ConfirmAction do 
  alias Proca.Action 
  alias Proca.Confirm
  import Proca.Changeset 
  import Proca.Repo

  def create(%Action{id: id}) do 
    %{
      operation: :confirm_action,
      subject_id: id
    } |> Confirm.create()
  end

  def run(%Confirm{operation: :confirm_action, subject_id: id}, :confirm, _) do 
    case get(Action, id) |> Action.confirm() do 
      {:ok, _} -> :ok 
      {:noop, _} -> :ok
      {:error, _} = e -> e
    end
  end

  def run(%Confirm{operation: :confirm_action, subject_id: id}, :reject, _) do 
    case get(Action, id) |> Action.reject() do 
      {:ok, _} -> :ok 
      {:noop, _} -> :ok
      {:error, _} = e -> e
    end
  end
end
